#!/system/bin/sh
# IRQ Kernel Sync - helper script (install + WebUI)
# Usage: irq_sync.sh build | status | set_prio <v> | sync | apply

MODDIR=$(cd "${0%/*}/.." 2>/dev/null && pwd)
MODID=irqbalance
TARGETS="$MODDIR/targets.list"   # lines: <module-relative file>|<real path>
DEFAULT_PRIO="1,1,1,1,0,0,0,0"
FLAG="$MODDIR/gpu_irq.on"        # exists = kgsl/msm_drm IRQs are added to IGNORED_IRQ
INTERRUPTS="${IRQ_PROC:-/proc/interrupts}"

# IRQ numbers of arch_timer / arm-pmu / arch_mem_timer
get_irqs() {
  out=""
  for k in arch_timer arm-pmu arch_mem_timer; do
    for n in $(grep -E "$k" "$INTERRUPTS" | awk '{print $1}' | tr -d ':'); do
      case "$n" in ''|*[!0-9]*) continue ;; esac
      case ",$out," in *",$n,"*) ;; *) out="${out:+$out,}$n" ;; esac
    done
  done
  echo "$out"
}

# IRQ numbers of the GPU (kgsl) and display (msm_drm)
gpu_irqs() {
  out=""
  for n in $(grep -E "kgsl-3d0|kgsl_3d0|msm_drm" "$INTERRUPTS" | awk '{print $1}' | tr -d ':'); do
    case "$n" in ''|*[!0-9]*) continue ;; esac
    case ",$out," in *",$n,"*) ;; *) out="${out:+$out,}$n" ;; esac
  done
  echo "$out"
}

merge_lists() {
  out=""
  for l in "$@"; do
    for n in $(echo "$l" | tr ',' ' '); do
      case ",$out," in *",$n,"*) ;; *) out="${out:+$out,}$n" ;; esac
    done
  done
  echo "$out"
}

# IGNORED_IRQ value: timers/PMU, plus GPU/display when the tweak is on (daemon accepts 20 max)
compute_ignored() {
  l=$(get_irqs)
  [ -f "$FLAG" ] && l=$(merge_lists "$l" "$(gpu_irqs)")
  echo "$l" | cut -d, -f1-20
}

# Every real msm_irqbalance.conf the device may use
find_confs() {
  {
    # 1) path passed with -f in the init .rc of the daemon
    for d in /vendor/etc/init /odm/etc/init /system/etc/init /system_ext/etc/init /product/etc/init; do
      grep -rhs "msm_irqbalance" "$d" 2>/dev/null | grep -o -- '-f [^ ]*' | awk '{print $2}'
    done
    # 2) usual locations
    for d in /vendor/etc /system/vendor/etc /odm/etc /vendor/odm/etc /product/etc \
             /system_ext/etc /system/etc /my_product/etc /my_engineering/etc \
             /my_company/etc /my_carrier/etc /my_region/etc /my_stock/etc \
             /my_heytap/etc /my_preload/etc /my_bigball/etc /my_manifest/etc; do
      echo "$d/msm_irqbalance.conf"
    done
    # 3) last resort: search
    find /vendor /odm /product /system_ext /system /my_* -maxdepth 4 -name msm_irqbalance.conf 2>/dev/null
  } | while read -r f; do
    [ -f "$f" ] && readlink -f "$f"
  done | sort -u
}

# real path -> module-relative path (the metamodule / magic mount handles the mounting)
map_path() {
  case "$1" in
    /system/*) echo "system${1#/system}" ;;
    *) echo "system$1" ;;
  esac
}

# PRIO to use: keep the user's value on updates, default on fresh installs
read_prio() {
  prev="/data/adb/modules/$MODID"
  if [ -f "$prev/targets.list" ]; then
    rel=$(head -n1 "$prev/targets.list"); rel=${rel%%|*}
    p=$(sed -n 's/^[[:space:]]*PRIO[[:space:]]*=[[:space:]]*//p' "$prev/$rel" 2>/dev/null | head -n1)
    echo "$p" | grep -Eq '^[0-9](,[0-9])*$' && { echo "$p"; return; }
  fi
  echo "$DEFAULT_PRIO"
}

# SELinux label the daemon needs to read the conf (never trust ls -Z of a file we already overlay)
ctx_for() {
  case "$1" in
    /vendor/*|/system/vendor/*|/odm/*|/system/odm/*) echo u:object_r:vendor_configs_file:s0 ;;
    *) c=$(ls -Z "$1" 2>/dev/null | awk '{print $1}'); echo "${c:-u:object_r:system_file:s0}" ;;
  esac
}

# re-apply labels (init resets them, so this runs on every boot)
fix_ctx() {
  [ -f "$TARGETS" ] || return 0
  while IFS='|' read -r rel real; do
    [ -f "$MODDIR/$rel" ] && chcon "$(ctx_for "$real")" "$MODDIR/$rel" 2>/dev/null
  done < "$TARGETS"
}

build() {
  prio=$(read_prio)
  [ -f "/data/adb/modules/$MODID/gpu_irq.on" ] && touch "$FLAG"
  irqs=$(compute_ignored)
  confs=$(find_confs)
  [ -z "$confs" ] && return 1
  rm -f "$TARGETS"
  for f in $confs; do
    rel=$(map_path "$f")
    mkdir -p "$MODDIR/${rel%/*}"
    {
      grep -vE '^[[:space:]]*(PRIO|IGNORED_IRQ)[[:space:]]*=|^#arch_timer' "$f"
      echo "PRIO=$prio"
      echo "#arch_timer, arm-pmu, arch_mem_timer"
      echo "IGNORED_IRQ=$irqs"
    } > "$MODDIR/$rel"
    ctx=$(ctx_for "$f")
    chmod 0644 "$MODDIR/$rel"; chown 0:0 "$MODDIR/$rel" 2>/dev/null
    chcon "$ctx" "$MODDIR/$rel" 2>/dev/null
    echo "$rel|$f" >> "$TARGETS"
    echo "   + $f"
  done
  echo "   PRIO=$prio"
  echo "   IGNORED_IRQ=$irqs"
  return 0
}

each_target() {  # $1 = sed expression-producing function name
  while IFS='|' read -r rel real; do
    [ -f "$MODDIR/$rel" ] && "$1" "$MODDIR/$rel"
  done < "$TARGETS"
}

set_key() {  # $1 key, $2 value, $3 file (rewritten in place, keeps inode/context)
  tmp="$3.tmp"
  grep -vE "^[[:space:]]*$1[[:space:]]*=" "$3" > "$tmp"
  echo "$1=$2" >> "$tmp"
  cat "$tmp" > "$3" && rm -f "$tmp"
}

set_prio() {
  echo "$1" | grep -Eq '^[0-9](,[0-9])*$' || { echo "ERR: invalid PRIO format"; exit 1; }
  while IFS='|' read -r rel real; do
    [ -f "$MODDIR/$rel" ] && set_key PRIO "$1" "$MODDIR/$rel"
  done < "$TARGETS"
  echo OK
}

sync_irqs() {
  irqs=$(compute_ignored)
  while IFS='|' read -r rel real; do
    [ -f "$MODDIR/$rel" ] && set_key IGNORED_IRQ "$irqs" "$MODDIR/$rel"
  done < "$TARGETS"
  echo "OK"
}

status() {
  [ -f "$TARGETS" ] || { echo "ERR: targets.list missing"; exit 1; }
  echo "CPUS=$(ls /sys/devices/system/cpu 2>/dev/null | grep -c '^cpu[0-9][0-9]*$')"
  first=""
  while IFS='|' read -r rel real; do
    echo "TARGET=$real"
    [ -z "$first" ] && [ -f "$MODDIR/$rel" ] && first="$MODDIR/$rel"
  done < "$TARGETS"
  [ -n "$first" ] || { echo "ERR: module conf file missing"; exit 1; }
  if [ -f "$FLAG" ]; then echo "GPU_IRQ=on"; else echo "GPU_IRQ=off"; fi
  echo "GPU_IRQS=$(gpu_irqs)"
  echo "CONF_BEGIN"
  cat "$first"
  echo "CONF_END"
}

gpu_on() {
  [ -n "$(gpu_irqs)" ] || { echo "ERR: no kgsl/msm_drm IRQs found"; exit 1; }
  touch "$FLAG"; sync_irqs
}

gpu_off() {
  rm -f "$FLAG"; sync_irqs
}

# health check used by the WebUI "Status" tab
check() {
  st=$(getprop init.svc.vendor.msm_irqbalance); echo "SERVICE=${st:-none}"
  echo "PID=$(pidof msm_irqbalance 2>/dev/null | awk '{print $1}')"
  if [ -f "$MODDIR/disable" ] || [ -f "$MODDIR/remove" ]; then echo "DISABLED=1"; else echo "DISABLED=0"; fi
  if [ -f "$TARGETS" ]; then
    while IFS='|' read -r rel real; do
      if [ ! -f "$real" ]; then m=missing
      elif [ "$(cat "$MODDIR/$rel" 2>/dev/null)" = "$(cat "$real" 2>/dev/null)" ]; then m=ok
      else m=diff; fi
      lab=$(ls -Z "$real" 2>/dev/null | awk '{print $1}')
      if [ "$lab" = "$(ctx_for "$real")" ]; then lok=1; else lok=0; fi
      echo "FILE|$real|$m|$lab|$lok"
    done < "$TARGETS"
  fi
  for i in /proc/irq/[0-9]*; do cat "$i/smp_affinity_list" 2>/dev/null; done | sort | uniq -c | sort -rn | while read -r c a; do echo "AFF|$a|$c"; done
}

# msm_irqbalance only reads the conf when it starts
apply() {
  for s in vendor.msm_irqbalance msm_irqbalance vendor.qti.msm_irqbalance; do
    if [ -n "$(getprop init.svc.$s)" ]; then
      setprop ctl.restart "$s" && { echo "OK: restarted $s"; return 0; }
    fi
  done
  pkill -x msm_irqbalance 2>/dev/null && { echo "OK: daemon killed, init restarts it"; return 0; }
  echo "WARN: daemon not found, reboot to apply"; return 1
}

case "$1" in
  build)    build ;;
  status)   status ;;
  set_prio) set_prio "$2" ;;
  sync)     sync_irqs ;;
  apply)    apply ;;
  fix_ctx)  fix_ctx ;;
  check)    check ;;
  gpu_on)   gpu_on ;;
  gpu_off)  gpu_off ;;
  *) echo "usage: $0 build|status|set_prio <v>|sync|apply"; exit 1 ;;
esac

uptime=$(cut -d. -f1 /proc/uptime) memory=$(cat /proc/meminfo|tr -s \ )

# FUNCIÓN SIMPLIFICADA - SIEMPRE IMPRIME
a() {
    sleep 0.01
    echo "$@"
}
echo ""
echo "▀█▀ ▒█▀▀█ ▒█▀▀█ "
echo "▒█░ ▒█▄▄▀ ▒█░▒█ "
echo "▄█▄ ▒█░▒█ ░▀▀█▄"
echo "▒█░▄▀ █▀▀ █▀▀█ █▀▀▄ █▀▀ █░░ "
echo "▒█▀▄░ █▀▀ █▄▄▀ █░░█ █▀▀ █░░ "
echo "▒█░▒█ ▀▀▀ ▀░▀▀ ▀░░▀ ▀▀▀ ▀▀▀"
echo "▒█▀▀▀█ █░░█ █▀▀▄ █▀▀ "
echo "░▀▀▀▄▄ █▄▄█ █░░█ █░░ "
echo "▒█▄▄▄█ ▄▄▄█ ▀░░▀ ▀▀▀"
echo ""
a "· OS: Android $(getprop ro.build.version.release)"
a "· Model: $(getprop ro.product.manufacturer) $(getprop ro.product.model)"
a "· Kernel: $(uname -r|cut -f1,2,3 -d-)"
a "· Uptime: $((uptime/3600)) hour, $((uptime%3600/60)) mins"
a "· Resolution:$(wm size|cut -d: -f2)"
a "· Terminal: $(cmd activity stack list|grep 0,0.*visible=true|tr -d ' '|cut -f1 -d/|cut -f2 -d:)"
a "· CPU: $(getprop ro.soc.manufacturer) $(getprop ro.soc.model) ($(grep proc /proc/cpuinfo|wc -l)) @ $(cat /sys/devices/system/cpu/cpufreq/*/cpuinfo_max_freq|tail -n1|awk '{printf("%.3f\n",$1/1000000)}')GHz"
a "· Memory: $((($(echo "$memory"|grep MemTotal|cut -f2 -d\ )-$(echo "$memory"|grep MemAvailable|cut -f2 -d\ ))/1024))MiB / $(($(echo "$memory"|grep MemTotal|cut -f2 -d\ )/1024))MiB"
echo ""
set_perm "$MODPATH/common/irq_sync.sh" 0 0 0755
set_perm "$MODPATH/post-fs-data.sh" 0 0 0755
set_perm "$MODPATH/service.sh" 0 0 0755

echo "- Looking for msm_irqbalance.conf..."
if ! sh "$MODPATH/common/irq_sync.sh" build; then
    echo ""
    abort "! msm_irqbalance.conf was not found on this device. Nothing was installed."
fi
echo ""
echo "- The msm_irqbalance.conf file(s) above will be replaced"
echo "   (systemless) and synchronized with the current kernel IRQs."
echo "- Open the module WebUI to edit PRIO="
echo ""
echo "+ By @LeanHijosdesusMadres"
echo ""

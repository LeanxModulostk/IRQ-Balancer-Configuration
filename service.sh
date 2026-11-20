#!/system/bin/sh
# Safety net: re-apply the label and restart the daemon if it is stuck restarting
MODDIR=${0%/*}
while [ "$(getprop sys.boot_completed)" != "1" ]; do sleep 2; done
sh "$MODDIR/common/irq_sync.sh" fix_ctx
sleep 10
[ "$(getprop init.svc.vendor.msm_irqbalance)" = "running" ] || sh "$MODDIR/common/irq_sync.sh" apply
exit 0

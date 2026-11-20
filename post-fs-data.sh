#!/system/bin/sh
# Fix the SELinux label of the overlaid msm_irqbalance.conf before the daemon starts
MODDIR=${0%/*}
sh "$MODDIR/common/irq_sync.sh" fix_ctx
exit 0

#!/system/bin/sh
MODDIR=${0%/*}

. $MODDIR/utils.sh

mask_val "7" /proc/irq/ZZZ/smp_affinity_list
mask_val "6" /proc/irq/XXX/smp_affinity_list

exit 0

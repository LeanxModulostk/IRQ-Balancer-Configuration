mkdir -p /dev/mount_masks

# $1:value $2:path
mask_val() {
    for file in $(find $2); do
        lock_val "$1" "$file"

        TIME="$(date "+%s%N")"
        echo "$1" >"/dev/mount_masks/mount_mask_$TIME"
        mount --bind "/dev/mount_masks/mount_mask_$TIME" "$file"
        restorecon -R -F "$file" > /dev/null 2>&1
    done
}

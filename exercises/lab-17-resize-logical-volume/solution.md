# Lab 17: Resize A Logical Volume Solution

## Task 01 - Resize logical volume /dev/reviewvg/reviewlv so the (clientvm) - 10 pts

```bash
lsblk -f
lvs
lvextend -L 320M /dev/reviewvg/reviewlv
blkid /dev/reviewvg/reviewlv
# if the filesystem is ext4, run resize2fs /dev/reviewvg/reviewlv
# if the filesystem is xfs, run xfs_growfs /mnt/reviewlv
df -hT /mnt/reviewlv
```

## Verification

```bash
lvs --noheadings -o lv_name,vg_name,lv_size --units m --nosuffix | awk '$1=="reviewlv" && $2=="reviewvg" && $3>=319 && $3<=321{found=1} END{exit !found}'
findmnt -no TARGET,SOURCE /mnt/reviewlv | grep -Eq '^/mnt/reviewlv /dev/mapper/reviewvg-reviewlv$'
```

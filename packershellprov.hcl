provisioner "shell" {
  inline = [
    "yum install -y lvm2",
    "pvcreate /dev/xvda",
    "vgcreate vg_root /dev/xvda",
    "lvcreate -L 20G -n lv_root vg_root",
    "lvcreate -L 10G -n lv_var vg_root",
    "lvcreate -L 10G -n lv_home vg_root",
    "lvcreate -L 10G -n lv_tmp vg_root",
    "lvcreate -L 10G -n lv_log vg_root",
    "lvcreate -L 10G -n lv_audit vg_root",
    "mkfs.xfs /dev/vg_root/lv_root",
    "mkfs.xfs /dev/vg_root/lv_var",
    "mkfs.xfs /dev/vg_root/lv_home",
    "mkfs.xfs /dev/vg_root/lv_tmp",
    "mkfs.xfs /dev/vg_root/lv_log",
    "mkfs.xfs /dev/vg_root/lv_audit",
    "mkdir -p /mnt/root /mnt/var /mnt/home /mnt/tmp /mnt/log /mnt/audit",
    "mount /dev/vg_root/lv_root /mnt/root",
    "mount /dev/vg_root/lv_var /mnt/var",
    "mount /dev/vg_root/lv_home /mnt/home",
    "mount /dev/vg_root/lv_tmp /mnt/tmp",
    "mount /dev/vg_root/lv_log /mnt/log",
    "mount /dev/vg_root/lv_audit /mnt/audit"
  ]
}

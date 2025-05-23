provisioner "shell" {
  inline = [
    "yum install -y lvm2",
    
    # Create LVM partitions
    "pvcreate /dev/xvda",
    "vgcreate vg_root /dev/xvda",
    "lvcreate -L 20G -n lv_root vg_root",
    "lvcreate -L 10G -n lv_var vg_root",
    "lvcreate -L 10G -n lv_home vg_root",
    "lvcreate -L 10G -n lv_tmp vg_root",
    "lvcreate -L 10G -n lv_log vg_root",
    "lvcreate -L 10G -n lv_audit vg_root",

    # Format the partitions
    "mkfs.xfs /dev/vg_root/lv_root",
    "mkfs.xfs /dev/vg_root/lv_var",
    "mkfs.xfs /dev/vg_root/lv_home",
    "mkfs.xfs /dev/vg_root/lv_tmp",
    "mkfs.xfs /dev/vg_root/lv_log",
    "mkfs.xfs /dev/vg_root/lv_audit",

    # Mount the partitions temporarily
    "mkdir -p /mnt/root /mnt/var /mnt/home /mnt/tmp /mnt/log /mnt/audit",
    "mount /dev/vg_root/lv_root /mnt/root",
    "mount /dev/vg_root/lv_var /mnt/var",
    "mount /dev/vg_root/lv_home /mnt/home",
    "mount /dev/vg_root/lv_tmp /mnt/tmp",
    "mount /dev/vg_root/lv_log /mnt/log",
    "mount /dev/vg_root/lv_audit /mnt/audit",

    # Copy ec2-user home directory
    "rsync -a /home/ec2-user/ /mnt/home/ec2-user/",

    # Adjust ownership and permissions
    "chown -R ec2-user:ec2-user /mnt/home/ec2-user",

    # Add entries to /etc/fstab for automatic mounting
    "echo '/dev/vg_root/lv_root / xfs defaults 0 0' >> /etc/fstab",
    "echo '/dev/vg_root/lv_var /var xfs defaults 0 0' >> /etc/fstab",
    "echo '/dev/vg_root/lv_home /home xfs defaults 0 0' >> /etc/fstab",
    "echo '/dev/vg_root/lv_tmp /tmp xfs defaults 0 0' >> /etc/fstab",
    "echo '/dev/vg_root/lv_log /var/log xfs defaults 0 0' >> /etc/fstab",
    "echo '/dev/vg_root/lv_audit /var/audit xfs defaults 0 0' >> /etc/fstab",

    # Unmount temporary mounts
    "umount /mnt/root /mnt/var /mnt/home /mnt/tmp /mnt/log /mnt/audit",

    # Remount with fstab entries
    "mount -a"
  ]
}

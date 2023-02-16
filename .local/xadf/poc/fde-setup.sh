#/bin/bash
# Full disk encryption setup script, will handle pre-installation environment
# settings, and some of the post-installation setups.
# Adapted from:
# https://help.ubuntu.com/community/Full_Disk_Encryption_Howto_2019

# Always switch to bash shell
bash
# prints current bash shell
echo $SHELL

fde-pre-install-select-device(){
cat <<EOF
################################################################################
# Identify Installation Target Device
################################################################################
EOF
echo "Our example uses /dev/sda, but do check suitable drives for installation."
echo "Output of lsbk:"
lsblk
read -p "Type a suitable device: " device
cat <<EOF
################################################################################
# set environment variables
################################################################################
# if uses NVME devices, use this instead:
# export DEV="/dev/nvme0n1"
# export DEV="/dev/sda"
EOF
export DEV="$device"

# Finally we'll set an environment variable for the encrypted device-mapper
# naming that omits the leading path "/dev/" part:
export DM="${DEV##*/}"

# And we have to cope with NVME devices needing a 'p' for partition suffix:
export DEVP="${DEV}$( if [[ "$DEV" =~ "nvme" ]]; then echo "p"; fi )"
export DM="${DM}$( if [[ "$DM" =~ "nvme" ]]; then echo "p"; fi )"

# Continue with partitioning
fde-pre-install-partitioning-check
}

fde-pre-install-partitioning-check(){
cat <<EOF
################################################################################
# Partitioning
################################################################################
# We'll now create a disk label and add four partitions. We'll be creating a GPT
# (GUID Partition Table) so it is compatible with both UEFI and BIOS mode
# installations. We'll also create partitions for both modes in addition to the
# partitions for the encrypted /boot/ and / (root) file-systems.
#
# We'll be using the sgdisk tool. To understand its options please read
# man 8 sgdisk
# 
# First check for any existing partitions on the device and if some are found
# consider if you wish to keep them or not. If you wish to keep them DO NOT USE
# sgdisk --zap-all command detailed next. Instead, consider if you need to free
# up disk space by shrinking or deleting individual existing partitions.
################################################################################
EOF
sgdisk --print $DEV

cat <<EOF
################################################################################
# If you do need to manipulate the existing partitions use GPartEd
# 
# If it is safe to delete everything on this device you should wipe out the
# existing partitioning metadata - DO NOT DO THIS if you are installing
# alongside existing partitions!
################################################################################

EOF
read -p "Is it safe to delete everything? (y/n) " zapall
if [[ "$zapall" == "y" ]]
then
  sgdisk --zap-all $DEV
  fde-pre-install-partitioning-drive
else
  echo "Cancel installation"
fi

}

fde-pre-install-partitioning-drive(){
cat <<EOF
################################################################################
# Now we'll create the partitions:
# => A small bios_boot (2MB) partition for BIOS-mode GRUB's core image,
# => an 128MB EFI System Partition,
# => a 768MB /boot/ and
# => a final partition for the remaining space for the operating system.
#
# Syntax: --new=<partition_number>:<start>:<end> where start and end can be
# relative values and when zero (0) adopt the lowest or highest possible value
# respectively.
#
# Partition 4 is not created. The reason is the Ubuntu Installer would only
# create partitions 1 and 5. Here we create those and in addition the two
# boot-loader alternatives.

Will generate /boot, EFI System Partition, and a partition for BIOS-mode GRUB's
core image, then will use the rest of the disk space for our operating system.
################################################################################
EOF
read -p "How big should /boot partition be: (rec. 768M) " sizeboot
read -p "How big should the ESP be: (rec. 128M) " sizeesp
echo "BIOS-mode GRUB's core image partition will be set to 2M"

# Fallback, return to default values if none is specified
[ "$sizeboot" == "" ] && sizeboot="768M"
[ "$sizeesp" == "" ] && sizeesp="128M"

echo "Partition /boot is set to $sizeboot"
echo "Partition ESP is set to $sizeesp"

# Create partitions
echo "Create partitions..."
# sgdisk --new=1:0:+768M $DEV  # /boot
sgdisk --new=1:0:+$sizeboot $DEV  # /boot
sgdisk --new=2:0:+2M $DEV    # bios_boot for BIOS-mode GRUB's core image
#sgdisk --new=3:0:+128M $DEV  # EFI System Partition
sgdisk --new=3:0:+$sizeesp $DEV  # EFI System Partition
sgdisk --new=5:0:0 $DEV      # for our operating system
# Formatting created partitions
echo "Formatting created partitions"
# As oneliner:
# sgdisk --typecode=1:8301 --typecode=2:ef02 --typecode=3:ef00 --typecode=5:8301 $DEV
# Assign GPT type codes for each of the partitions
sgdisk --typecode=1:8301 $DEV # "Linux reserved"
sgdisk --typecode=2:ef02 $DEV # "BIOS boot partition"
sgdisk --typecode=3:ef00 $DEV # "EFI System"
sgdisk --typecode=5:8301 $DEV # "Linux reserved"
cat <<EOF
Change drive names:
/boot partition > /boot
BIOS-mode GRUB  > GRUB
EFI Storage Part> EFI-SP
Remaining space > rootfs
EOF
# Change drive names
sgdisk --change-name=1:/boot $DEV  # for /boot
sgdisk --change-name=2:GRUB $DEV   # for GRUB
sgdisk --change-name=3:EFI-SP $DEV # for EFI
sgdisk --change-name=5:rootfs $DEV # for our rootfs
#sgdisk \                    # Change drive names
#--change-name=1:/boot \     # for /boot
#--change-name=2:GRUB \      # for GRUB
#--change-name=3:EFI-SP \    # for EFI
#--change-name=5:rootfs $DEV # for our rootfs

# Don't know what it does
sgdisk --hybrid 1:2:3 $DEV

# Display the current structure
echo "Display the current structure"
sgdisk --print $DEV

cat <<EOF
################################################################################
# LUKS Encrypt
################################################################################
# The default LUKS (Linux Unified Key Setup) format (version) used by the
# cryptsetup tool has changed since the release of 18.04 Bionic. 18.04 used
# version 1 ("luks1") but more recent Ubuntu releases default to version 2
# ("luks2"). GRUB only supports opening version 1 so we have to explicitly set
# luks1 in the commands we use or else GRUB will not be able to install to, or
# unlock, the encrypted device.
#
# Note: as of October 2021 and Ubuntu 21.10 GRUB still does not yet support
# installing to luks2 containers. It can read luks2 (although with several
# strict limitations, and subject to some bugs decoding UUIDs) but grub-install
# via grub-probe cannot recognise a luks2 device and therefore cannot correctly
# install into luks2 containers.
# 
# In summary, the LUKS container for /boot/ must currently use LUKS version 1
# whereas the container for the operating system's root file-system can use the
# default LUKS version 2.
#

# First the /boot/ partition:
cryptsetup luksFormat --type=luks1 ${DEVP}1
EOF

# First the /boot/ partition:
cryptsetup luksFormat --type=luks1 ${DEVP}1

cat <<EOF

# Now the operating system partition:
cryptsetup luksFormat ${DEVP}5

EOF

# Now the operating system partition:
cryptsetup luksFormat ${DEVP}5

cat <<EOF
################################################################################
# LUKS unlock
################################################################################
# Now open the encrypted devices:
EOF

cryptsetup open ${DEVP}1 LUKS_BOOT
cryptsetup open ${DEVP}5 ${DM}5_crypt

# Display unlocked encrypted drives
echo "# Display unlocked encrypted drives"
ls /dev/mapper/

cat <<EOF
# After the Ubuntu installation is finished we will be adding key-files to both
# of these devices so that you'll only have to type the pass-phrase once for
# GRUB and thereafter the operating system will use embedded key-files to unlock
# without user intervention.

################################################################################
# Format File-systems
################################################################################

# IMPORTANT this step must be done otherwise the Installer's partitioner will
# disable the ability to write a file-system to this device without it having a
# partition table:

EOF

mkfs.ext4 -L boot /dev/mapper/LUKS_BOOT

# Format the EFI-SP as FAT16:
echo "Format the EFI-SP as FAT16:"
mkfs.vfat -F 16 -n EFI-SP ${DEVP}3

cat <<EOF
################################################################################
# LVM (Logical Volume Management)
################################################################################
# We'll now create the operating system LVM Volume Group (VG) and a Logical
# Volume (LV) for the root file-system.
#
# LVM has a wonderful facility of being able to increase the size of an LV
# whilst it is active. To provide for this we will only allocate 80% of the free
# space in the VG to the LV initially. Later, if you need space for other file-
# systems, or snapshots, the installed system will be ready and able to support
# those requirements without struggling to free up space.
#
# I am also creating a 4GiB LV device for swap which, as well as being used to
# provide additional memory pages when free RAM space is low, is used to store a
# hibernation image of memory so the system can be completely powered off and
# can resume all applications where they left off. The size of the swap space to
# support hibernation should be equal to the amount of RAM the PC has now or is
# is expected to have in the future.
# 
# Note: Since the 22.04 release of codename Jammy (April 2022) the naming of the
# VG by the installer has changed; hyphens have been removed and the name format
# changed. The format is now vg${flavour} where ${flavour} might be e.g:
# "ubuntu" or "kubuntu"). In order to make the commands listed here-after work
# precisely we now add an extra step to put the VG name into a variable and use
# that in subsequent instructions. ToDo: I will go back over previous installers
# for 18.04 and 20.04 to ensure this all still works.

EOF

flavour="$( sed -n 's/.*cdrom:\[\([^ ]*\).*/\1/p' /etc/apt/sources.list )"
release="$( lsb_release -sr | tr -d . )"
if [ ${release} -ge 2204 ]; then
  VGNAME="vg${flavour,,}"
else
  VGNAME="${flavour}--vg"
fi
export VGNAME

# Initialize physical volume for use by LVM
echo "Initialize physical volume for use by LVM"
pvcreate /dev/mapper/${DM}5_crypt
# Create a volume group
echo "Create a volume group"
vgcreate "${VGNAME}" /dev/mapper/${DM}5_crypt
# Create a logical volume for root
echo "Create a logical volume for root"
lvcreate -L 100G -n root "${VGNAME}"
# Create a logical volume for swap
echo "Create a logical volume for swap"
lvcreate -L 8G -n swap_1 "${VGNAME}"
# Create a logical volume for home, occupying 80% of free space
echo "Create a logical volume for home, occupying 80% of free space"
lvcreate -l 80%FREE -n home "${VGNAME}"

cat <<EOF
################################################################################
# Now stop, and start the installation process, fill up the prompts. Then you
# can immediately continue to the next stage before the installer reaches the
# Install Bootloader stage at the end of the installation process.
# 
# After you completed the forms, return to the Terminal and run the following
# command: fde-mid-install
################################################################################
EOF
}

fde-mid-install(){
cat <<EOF
################################################################################
# Enable Encrypted GRUB
################################################################################
# As soon as you have completed those forms switch to the Terminal to configure
# GRUB. These commands wait until the installer has created the GRUB directories
# and then adds a drop-in file telling GRUB to use an encrypted file-system. The
# command will not return to the shell prompt until the target directory has
# been created by the installer. In most cases that will have been done before
# this command is executed so it should instantly return:

EOF

echo "This has to be done before the installer reaches the Install Bootloader"
echo "stage at the end of the installation process."
while [ ! -d /target/etc/default/grub.d ]
do
  sleep 1
done
echo "GRUB_ENABLE_CRYPTODISK=y" > /target/etc/default/grub.d/local.cfg

cat <<EOF
################################################################################
# Now wait until the installation is completed, and continue to the next stage.
# After the installation is completed, run:
# ~$ fde-post-install
################################################################################
EOF
}

fde-post-install(){
# Return to the Terminal and create a change-root environment to work in the
# newly installed OS.
echo "Create a change-root environment to work in the newly installed OS."
echo "Mount /dev/mapper/${VGNAME}-root to /target"
# Mount to target
mount /dev/mapper/${VGNAME}-root /target
echo "Mount necessary directories to /target/"
for n in proc sys dev etc/resolv.conf;
do
  mount --rbind /$n /target/$n
done 
# Chroot to target
echo "Chroot to /target"
chroot /target

echo "Begin installation in chroot env"
fde-install-chroot

}

fde-install-chroot(){
echo "In chroot, mount all"
mount -a
cat <<EOF
# Within the chroot install and configure the cryptsetup-initramfs package. This
# may already be installed. Note: this package is not available in 18.04 Bionic
# because the files are included in the main cryptsetup package.

apt install -y cryptsetup-initramfs
EOF
apt install -y cryptsetup-initramfs

cat <<EOF
# This allows the encrypted volumes to be automatically unlocked at boot-time.
# The key-file and supporting scripts are added to the
# /boot/initrd.img-$VERSION files.
#
# This is safe because these files are themselves stored in the encrypted /boot/
# which is unlocked by the GRUB boot-loader (which asks you to type the
# pass-phrase) which then loads the kernel and initrd.img into RAM before
# handing execution over to the kernel.

EOF
echo "Modify /etc/cryptsetup-initramfs/conf-hook"
echo "KEYFILE_PATTERN=/etc/luks/*.keyfile" >> /etc/cryptsetup-initramfs/conf-hook
echo "Add UMASK to /etc/initramfs-tools/initramfs.conf"
echo "UMASK=0077" >> /etc/initramfs-tools/initramfs.conf

cat <<EOF
# Create a randomised key-file of 4096 bits (512 bytes), secure it, and add it
# to the LUKS volumes

EOF

echo "Make /etc/luks directory"
mkdir /etc/luks
echo "Take the first 512 bits of /dev/urandom and put it to /etc/luks/boot_os.keyfile"
dd if=/dev/urandom of=/etc/luks/boot_os.keyfile bs=512 count=1
echo "Do chmod to /etc/luks and the created keyfile"
chmod u=rx,go-rwx /etc/luks
chmod u=r,go-rwx /etc/luks/boot_os.keyfile
echo "Add the created keys to ${DEVP}1 and ${DEVP}5"
cryptsetup luksAddKey ${DEVP}1 /etc/luks/boot_os.keyfile
cryptsetup luksAddKey ${DEVP}5 /etc/luks/boot_os.keyfile

# Add the keys to the crypttab (Man-pages for crypttab blkid):
echo "Add the keys to the crypttab"
echo "LUKS_BOOT UUID=$(blkid -s UUID -o value ${DEVP}1) /etc/luks/boot_os.keyfile luks,discard" >> /etc/crypttab
echo "${DM}5_crypt UUID=$(blkid -s UUID -o value ${DEVP}5) /etc/luks/boot_os.keyfile luks,discard" >> /etc/crypttab

# Finally update the initialramfs files to add the cryptsetup unlocking scripts
# and the key-file:
echo "Update initialramfs files to account for cryptestup unlocking and keyfile"
update-initramfs -u -k all
}


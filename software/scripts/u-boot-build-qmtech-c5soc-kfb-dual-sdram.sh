# 1. Set the Project's 'Top' directory - this is the folder that contains the GSRD, Software, Tools, etc.
export U_BOOT_BUILD_SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd ) # The script must be placed at the top/overhead place
export PROJ_TOP_FOLDER=$U_BOOT_BUILD_SCRIPT_DIR

export GHRD_TOP_FOLDER=/home/monklp/workspace/GITHUB/@monkstein88/qmtech_c5soc_kfb_dual_sdram_ghrd
export UBOOT_TOP_FOLDER=/home/monklp/workspace/GITHUB/@monkstein88/u-boot-socfpga
echo $GHRD_TOP_FOLDER

# 2. Set the ARM linux build toolchaing for U-Boot compilation
#export PATH=$PROJ_TOP_FOLDER/toolchain/arm-gnu-toolchain-15.2.rel1-x86_64-arm-none-linux-gnueabihf/bin:$PATH
export PATH=/home/monklp/workspace/arm-gnu-toolchain-15.2.rel1-x86_64-arm-none-linux-gnueabihf/bin:$PATH
export ARCH=arm
export CROSS_COMPILE=arm-none-linux-gnueabihf-

# 3. Build U-Boot
cd $PROJ_TOP_FOLDER/software/u-boot-socfpga
make mrproper
sync
make clean
sync
cd $PROJ_TOP_FOLDER/software/u-boot-socfpga/arch/arm/mach-socfpga/cv_bsp_generator
python2.7 cv_bsp_generator.py -i $PROJ_TOP_FOLDER/qmtech_c5soc_kfb_ghrd/quartus/hps_isw_handoff/soc_system_hps_0 -o ../../../../board/qmtech/c5soc-kfb-dual-sdram/qts
cd $PROJ_TOP_FOLDER/software/u-boot-socfpga
make socfpga_c5soc_kfb_dual_sdram_defconfig
sync
make -j 
sync

# For U-Boot 2024.7
# 4. Insert a SD-Card in your PC, prepare, partition and flash it with the U-Boot image
cd $PROJ_TOP_FOLDER
lsblk # Check which device is the SD-Card top partition - in the below case its 'sdb'
#NAME   MAJ:MIN RM   SIZE RO TYPE MOUNTPOINTS
#sda      8:0    0 476,9G  0 disk 
#├─sda1   8:1    0   123M  0 part /boot/efi
#├─sda2   8:2    0   123M  0 part 
#└─sda3   8:3    0   473G  0 part /
#sdb      8:16   1  29,7G  0 disk 
#├─sdb1   8:17   1     1M  0 part 
#├─sdb2   8:18   1   511M  0 part 
#└─sdb3   8:19   1  29,2G  0 part 
export SDCARD_DEV=/dev/sdb
sudo umount $SDCARD_DEV*
sync
sudo wipefs -a $SDCARD_DEV
sync
sudo dd if=/dev/zero of=$SDCARD_DEV bs=1M count=10 conv=sync  # zeros the first 10MB
sync
# Here is a code snippet of commands you can run to create the partitions, set the partition type, and format the partitions.
sudo parted --script $SDCARD_DEV mklabel msdos
sync
sudo parted --script $SDCARD_DEV mkpart primary 2048s 4095s # This is the 1st partition
sync
sudo parted --script $SDCARD_DEV mkpart primary fat32 4096s 1050623s # This is the 2nd partition
sync
sudo parted --script $SDCARD_DEV mkpart primary ext4 1050624s 100%  # This is the 3rd partition
sync
sudo sfdisk --part-type $SDCARD_DEV 1 a2 # The first partition of must be of type A2 and will be filled with the u-boot pre-loader
sync
sudo mkfs.vfat -F 32 ${SDCARD_DEV}2
sync
sudo mkfs.ext4 -F ${SDCARD_DEV}3 
sync
# Now, in order to boot to the U-Boot prompt, complete this commands.
cd $PROJ_TOP_FOLDER/software/u-boot-socfpga
sudo dd if=u-boot-with-spl.sfp of=${SDCARD_DEV}1 bs=512 conv=sync
sudo sync
sudo umount $SDCARD_DEV*
sync



# For U-Boot v2026.1
# Here is a code snippet of commands you can run to create the partitions, set the partition type, and format the partitions.
export SDCARD_DEV=/dev/sdb
sudo umount $SDCARD_DEV*
sync
sudo wipefs -a $SDCARD_DEV        # wipes partition table and filesystem signatures
sync
sudo dd if=/dev/zero of=$SDCARD_DEV bs=1M count=10 conv=sync  # zeros the first 10MB
sync
sudo fdisk -l /dev/sdb
sync
sudo umount $SDCARD_DEV*
sync
sudo parted --script $SDCARD_DEV mklabel msdos
sync
sudo parted --script $SDCARD_DEV mkpart primary fat32 1MiB 15MiB # This is the 1st partition
sync
sudo parted --script $SDCARD_DEV set 1 boot on
sync
sudo parted --script $SDCARD_DEV mkpart primary       16MiB 32MiB # This is the 2nd partition
sync
sudo sfdisk --part-type $SDCARD_DEV 2 a2 # The second partition of must be of type A2 and will be filled with the u-boot pre-loader
sync
sudo mkfs.vfat -F 32 ${SDCARD_DEV}1 #  The first partition of must be of type fat and will be used to place the u-boot.img
sync
sudo mount ${SDCARD_DEV}1 /mnt/boot
sync
sudo dd if=u-boot.img of=${SDCARD_DEV}1 bs=512 conv=sync
sync
sudo cp u-boot.img /mnt/boot
sync
sudo umount /mnt/boot
sync
sudo dd if=u-boot-with-spl.sfp of=${SDCARD_DEV}2 bs=512 conv=sync
sync
sudo umount $SDCARD_DEV*
sync



export SDCARD_DEV=/dev/sdb
sudo umount $SDCARD_DEV*
sync
sudo wipefs -a $SDCARD_DEV        # wipes partition table and filesystem signatures
sudo dd if=/dev/zero of=$SDCARD_DEV bs=1M count=10 conv=sync  # zeros the first 10MB
sync
sudo fdisk -l $SDCARD_DEV  # should show no valid partition table
sync
# Wipe and partition
sudo parted $SDCARD_DEV -- mklabel msdos
sudo parted $SDCARD_DEV -- mkpart primary fat32  2048s      32767s      # part1 FAT32 0 - 16MB
sudo parted $SDCARD_DEV -- mkpart primary ext4   32768s     1048575s    # part2 ext4  16MB - 512MB
sudo parted $SDCARD_DEV -- mkpart primary        1048576s   1049599s    # part3 RAW    512 - 513MB
sudo parted $SDCARD_DEV -- set 1 boot on
# Format partitions 1 and 2 (NOT 3)
sudo mkfs.vfat -F 32 -n BOOT  ${SDCARD_DEV}1
sudo mkfs.ext4 -L rootfs      ${SDCARD_DEV}2
sudo parted $SDCARD_DEV -- type 3 0xa2
# partition 3 — NO mkfs, written raw
sudo dd if=u-boot-with-spl.sfp of=${SDCARD_DEV}3 bs=512 conv=sync
sync


cd $PROJ_TOP_FOLDER
rm -rf sdcard && mkdir sdcard -p 
export SDCARD_MNT=$PROJ_TOP_FOLDER/sdcard/ # This directory will be used as mounting point for the SD Card
sudo mount ${SDCARD_DEV}2 $SDCARD_MNT
sudo cp u-boot.img $SDCARD_MNT
sudo sync
sudo umount $SDCARD_MNT
sudo sync


# ================================

export GHRD_TOP_FOLDER=/home/monklp/workspace/GITHUB/@monkstein88/qmtech_c5soc_kfb_dual_sdram_ghrd  # 'main' branch
export UBOOT_TOP_FOLDER=/home/monklp/workspace/GITHUB/@monkstein88/u-boot-socfpga                   # 'qmtech_c5soc_kfb_dual_sdram_v2024.07' branch
echo $GHRD_TOP_FOLDER
echo $UBOOT_TOP_FOLDER

cd $GHRD_TOP_FOLDER # directory could be reached. Ok.
cd $UBOOT_TOP_FOLDER # directory could be reached. Ok.

# 
cd $UBOOT_TOP_FOLDER/arch/arm/mach-socfpga/cv_bsp_generator
python2.7 cv_bsp_generator.py -i $GHRD_TOP_FOLDER/quartus/hps_isw_handoff/soc_system_hps_0 -o ../../../../board/qmtech/c5soc-kfb-dual-sdram/qts
git clean -f # remove the extra generated .pyc files from the run of the 'cv_bsp_generator'

# Compile/Build Preloaded + Uboot
export PATH=/home/monklp/workspace/arm-gnu-toolchain-15.2.rel1-x86_64-arm-none-linux-gnueabihf/bin:$PATH
export ARCH=arm
export CROSS_COMPILE=arm-none-linux-gnueabihf-
cd $UBOOT_TOP_FOLDER
make socfpga_c5soc_kfb_dual_sdram_defconfig
sync
make -j 8 
sync
# The following ()important) files were generated sucesfully:
#  ...
#  DTC     arch/arm/dts/socfpga_cyclone5_kfb_dual_sdram.dtb 
#  ...
#  OBJCOPY spl/u-boot-spl-nodtb.bin
#  SYM     spl/u-boot-spl.sym
#  CAT     spl/u-boot-spl-dtb.bin
#  COPY    spl/u-boot-spl.bin
#  MKIMAGE spl/u-boot-spl.sfp
#  SOCBOOT u-boot-with-spl.sfp
#  OFCHK   .config

























# Here is a code snippet of commands you can run to create the partitions, set the partition type, and format the partitions.
export SDCARD_DEV=/dev/sdb
sudo umount $SDCARD_DEV*
sync
sudo wipefs -a $SDCARD_DEV        # wipes partition table and filesystem signatures
sync
sudo dd if=/dev/zero of=$SDCARD_DEV bs=1M count=10 conv=sync  # zeros the first 10MB
sync

# ...
# ...
# ...

# Unmount (all) partitions and eject the SD Card 
sudo umount $SDCARD_DEV*
sync
sudo eject $SDCARD_DEV
sync


#
# SPDX-FileCopyrightText: The LineageOS Project
# SPDX-License-Identifier: Apache-2.0
#
# LineageOS 22.2 (Android 15) board config for the Lenovo Tab One
# (TB305FU / clove_row_wifi). MediaTek MT6768/MT8786 family, GKI 6.6 kernel.
#
# Lenovo has not released matching kernel source, so this tree ships the STOCK
# GKI kernel Image, DTB and DTBO as prebuilts and reuses the stock vendor,
# vendor_dlkm, odm_dlkm and system_dlkm partitions. LineageOS builds only the
# system / system_ext / product side. See README.md for the full strategy and
# the constraints inherited from the TWRP port.
#

DEVICE_PATH := device/lenovo/clove_row_wifi

# Architecture
TARGET_ARCH := arm64
TARGET_ARCH_VARIANT := armv8-a
TARGET_CPU_ABI := arm64-v8a
TARGET_CPU_ABI2 :=
TARGET_CPU_VARIANT := cortex-a53
TARGET_CPU_VARIANT_RUNTIME := cortex-a53

TARGET_2ND_ARCH := arm
TARGET_2ND_ARCH_VARIANT := armv8-a
TARGET_2ND_CPU_ABI := armeabi-v7a
TARGET_2ND_CPU_ABI2 := armeabi
TARGET_2ND_CPU_VARIANT := cortex-a53
TARGET_2ND_CPU_VARIANT_RUNTIME := cortex-a53

TARGET_SUPPORTS_64_BIT_APPS := true

# Platform
TARGET_BOARD_PLATFORM := mt6768
TARGET_BOOTLOADER_BOARD_NAME := clove_row_wifi
TARGET_NO_BOOTLOADER := true

# Kernel — prebuilt stock GKI 6.6 (no source released by Lenovo)
TARGET_NO_KERNEL := false
TARGET_PREBUILT_KERNEL := $(DEVICE_PATH)/prebuilt/kernel
BOARD_PREBUILT_DTBIMAGE_DIR := $(DEVICE_PATH)/prebuilt/dtb
BOARD_INCLUDE_DTB_IN_BOOTIMG := true
BOARD_PREBUILT_DTBOIMAGE := $(DEVICE_PATH)/prebuilt/dtbo.img

# Stock Android 15 GKI boot image geometry (header v4, 4 KiB pages)
BOARD_BOOT_HEADER_VERSION := 4
BOARD_KERNEL_PAGESIZE := 4096
BOARD_KERNEL_BASE := 0x40000000
BOARD_KERNEL_OFFSET := 0x00080000
BOARD_RAMDISK_OFFSET := 0x07c80000
BOARD_KERNEL_TAGS_OFFSET := 0x0bc80000
BOARD_DTB_OFFSET := 0x0bc80000
BOARD_KERNEL_CMDLINE := bootopt=64S3,32N2,64N2
BOARD_MKBOOTIMG_ARGS += --header_version $(BOARD_BOOT_HEADER_VERSION)
BOARD_MKBOOTIMG_ARGS += --kernel_offset $(BOARD_KERNEL_OFFSET)
BOARD_MKBOOTIMG_ARGS += --ramdisk_offset $(BOARD_RAMDISK_OFFSET)
BOARD_MKBOOTIMG_ARGS += --tags_offset $(BOARD_KERNEL_TAGS_OFFSET)
BOARD_MKBOOTIMG_ARGS += --dtb_offset $(BOARD_DTB_OFFSET)
BOARD_RAMDISK_USE_LZ4 := true

# A/B with Virtual A/B snapshots (matches stock)
AB_OTA_UPDATER := true
BOARD_USES_RECOVERY_AS_BOOT :=
TARGET_NO_RECOVERY := true
BOARD_MOVE_RECOVERY_RESOURCES_TO_VENDOR_BOOT := true
BOARD_INCLUDE_RECOVERY_RAMDISK_IN_VENDOR_BOOT := true

# Stock firmware updates all of boot/dtbo/init_boot/vendor*/...; this port only
# produces the system side, so only those are listed. Adding partitions we do
# not build makes update_engine demand images that never get generated.
AB_OTA_PARTITIONS += \
    product \
    system \
    system_ext \
    vbmeta_system

BOARD_PARTIAL_OTA_UPDATE_PARTITIONS_LIST := \
    system \
    system_ext \
    product

# Virtual A/B (compression.mk is inherited in the product makefile)
BOARD_SUPER_PARTITION_METADATA_DEVICE := super

# Dynamic / super partition
BOARD_SUPER_PARTITION_SIZE := 11811160064
BOARD_SUPER_PARTITION_GROUPS := clove_dynamic_partitions
# Only built partitions belong in the group. The stock vendor, vendor_dlkm,
# odm_dlkm and system_dlkm logical partitions stay in place on the device and
# are flashed/resized individually via fastbootd.
BOARD_CLOVE_DYNAMIC_PARTITIONS_PARTITION_LIST := \
    system \
    system_ext \
    product
# Max group size = super/2 - overhead (A/B). Leave slack under the 5.9 GiB slot.
BOARD_CLOVE_DYNAMIC_PARTITIONS_SIZE := 5804453888
# PRODUCT_USE_DYNAMIC_PARTITIONS is a PRODUCT variable and is already set (and
# made readonly) by lineage_clove_row_wifi.mk before BoardConfig.mk is parsed.
# Setting it here is a hard build error -- keep it in the product makefile only.
BOARD_BUILD_SUPER_IMAGE_BY_DEFAULT := false

# Static partition image sizes
BOARD_BOOTIMAGE_PARTITION_SIZE := 33554432
BOARD_VENDOR_BOOTIMAGE_PARTITION_SIZE := 67108864
BOARD_INIT_BOOT_IMAGE_PARTITION_SIZE := 8388608
BOARD_DTBOIMG_PARTITION_SIZE := 8388608
BOARD_FLASH_BLOCK_SIZE := 262144

# Filesystems — stock uses EROFS for read-only logical partitions, F2FS userdata
TARGET_USERIMAGES_USE_EXT4 := true
TARGET_USERIMAGES_USE_F2FS := true
BOARD_SYSTEMIMAGE_FILE_SYSTEM_TYPE := erofs
BOARD_SYSTEM_EXTIMAGE_FILE_SYSTEM_TYPE := erofs
BOARD_PRODUCTIMAGE_FILE_SYSTEM_TYPE := erofs
BOARD_EROFS_COMPRESSOR := lz4hc,9
BOARD_EROFS_PCLUSTER_SIZE := 65536

# Only the partitions this port actually BUILDS are declared here. Setting
# TARGET_COPY_OUT_VENDOR_DLKM/ODM_DLKM/SYSTEM_DLKM tells the build to produce
# those images and then demands a filesystem type for each -- but vendor and
# all three *_dlkm partitions are kept from stock firmware, so they must stay
# unset and keep their defaults.
TARGET_COPY_OUT_SYSTEM := system
TARGET_COPY_OUT_SYSTEM_EXT := system_ext
TARGET_COPY_OUT_PRODUCT := product

# TARGET_COPY_OUT_VENDOR MUST be 'vendor', even though this port does not ship
# the vendor image it builds. If it is left unset, board_config.mk silently
# defaults it to the legacy 'system/vendor', and the build then emits /vendor
# as a SYMLINK to /system/vendor instead of a real directory. A partition
# cannot be mounted onto a symlink, so first-stage init mounts system and
# system_ext, fails on vendor, and the device bootloops with
#   Kernel panic - not syncing: Attempted to kill init!
# This cost a full flash/bootloop/forensics cycle to find. Do not remove it.
#
# Setting it to 'vendor' implies BOARD_USES_VENDORIMAGE, which in turn demands
# a filesystem type, so declare one. The resulting vendor.img is simply not
# used -- the stock vendor partition is kept (see device.mk).
TARGET_COPY_OUT_VENDOR := vendor
BOARD_VENDORIMAGE_FILE_SYSTEM_TYPE := erofs

# Metadata encryption partition (dm-default-key on userdata)
BOARD_USES_METADATA_PARTITION := true

# Recovery / fstab
TARGET_RECOVERY_FSTAB := $(DEVICE_PATH)/rootdir/etc/fstab.mt6768
TARGET_RECOVERY_PIXEL_FORMAT := BGRA_8888

# Vendor blobs live in vendor/lenovo/clove_row_wifi
# (generated by extract-files.py against stock firmware).
# Legacy MTK blobs can trip ELF prebuilt validation.
BUILD_BROKEN_ELF_PREBUILT_PRODUCT_COPY_FILES := true
BUILD_BROKEN_PREBUILT_ELF_FILES := true

# SELinux
#
# This port KEEPS the stock vendor partition, and that partition already ships
# a complete, self-contained policy under /vendor/etc/selinux:
#   vendor_sepolicy.cil (1.3M), plat_pub_versioned.cil, precompiled_sepolicy,
#   vendor_{file,property,service,hwservice,seapp}_contexts, ...
# Every Microtrust/Beanpod TEE type the crypto stack needs (teei_*, tee_exec,
# hal_keymaster_default, teei_hal_thh, ...) is defined there already.
#
# It declares plat_sepolicy_vers.txt = 202404, which is exactly the Android 15
# platform policy version that LineageOS 22.2 builds. Vendor and platform are
# the same version, so NO compatibility mapping shim is required. (This is a
# concrete reason the port targets LOS 22 rather than 23/Android 16.)
#
# We therefore deliberately do NOT:
#   - set BOARD_VENDOR_SEPOLICY_DIRS  -- no vendor image is built, so any
#     policy put there would never ship, and
#   - include device/mediatek/sepolicy_vndr/SEPolicy.mk -- that is for devices
#     which REBUILD vendor from blobs.
# Adding either builds policy that goes nowhere and masks real errors.
#
# Only the system side is extended, for LineageOS-specific additions:
SYSTEM_EXT_PRIVATE_SEPOLICY_DIRS += $(DEVICE_PATH)/sepolicy/private
#
# NOTE: our rebuilt plat_sepolicy.cil will not match the vendor's
# precompiled_sepolicy.plat_sepolicy_and_mapping.sha256
# (201d593e465d235d5546e96d8720b6a4ba091257bdeb9e79d0f8825223ea2763), so init
# discards the precompiled policy and compiles from CIL on every boot. That is
# expected and correct for a custom system build; it costs ~1s of boot time and
# requires those vendor CIL files to remain present.

# Security patch level (stock ZUI 17 / Android 15)
VENDOR_SECURITY_PATCH := 2026-05-05
BOOT_SECURITY_PATCH := 2026-05-05

# Properties
TARGET_SYSTEM_PROP += $(DEVICE_PATH)/system.prop
TARGET_VENDOR_PROP += $(DEVICE_PATH)/vendor.prop

# VINTF
DEVICE_MANIFEST_FILE := $(DEVICE_PATH)/configs/vintf/manifest.xml
DEVICE_MATRIX_FILE := $(DEVICE_PATH)/configs/vintf/compatibility_matrix.xml

# Verified Boot
# Stock LK enforces AVB against signed vbmeta. Custom builds require an
# LK dm-verity patch (see TWRP notes) or a locked/patched vbmeta. Use AOSP
# test keys for now; flashing strategy is documented in README.md.
BOARD_AVB_ENABLE := true
BOARD_AVB_MAKE_VBMETA_IMAGE_ARGS += --flags 3
BOARD_AVB_ALGORITHM := SHA256_RSA4096
BOARD_AVB_KEY_PATH := external/avb/test/data/testkey_rsa4096.pem
BOARD_AVB_ROLLBACK_INDEX := 0

BOARD_AVB_VBMETA_SYSTEM := system system_ext product
BOARD_AVB_VBMETA_SYSTEM_KEY_PATH := external/avb/test/data/testkey_rsa4096.pem
BOARD_AVB_VBMETA_SYSTEM_ALGORITHM := SHA256_RSA4096
BOARD_AVB_VBMETA_SYSTEM_ROLLBACK_INDEX := 0
BOARD_AVB_VBMETA_SYSTEM_ROLLBACK_INDEX_LOCATION := 1

# Inherit proprietary blob board config (generated by extract-files.py)
-include vendor/lenovo/clove_row_wifi/BoardConfigVendor.mk

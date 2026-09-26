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

# Kernel: prebuilt, from device/lenovo/clove_row_wifi-kernel (see its README).
# Image.gz and system_dlkm modules are an unmodified AOSP GKI android15-6.6
# build; vendor_dlkm / vendor_ramdisk modules, DTB and DTBO are stock Lenovo.
KERNEL_PATH := $(DEVICE_PATH)-kernel
TARGET_NO_KERNEL := false
TARGET_PREBUILT_KERNEL := $(KERNEL_PATH)/Image.gz
TARGET_PREBUILT_KERNEL_HEADERS := $(KERNEL_PATH)/kernel-uapi-headers.tar.gz
BOARD_PREBUILT_DTBIMAGE_DIR := $(KERNEL_PATH)/dtb
BOARD_INCLUDE_DTB_IN_BOOTIMG := true
BOARD_PREBUILT_DTBOIMAGE := $(KERNEL_PATH)/dtbo.img

# Kernel modules
BOARD_SYSTEM_KERNEL_MODULES := $(wildcard $(KERNEL_PATH)/modules/system_dlkm/*.ko)
BOARD_SYSTEM_KERNEL_MODULES_LOAD := $(strip $(shell cat $(KERNEL_PATH)/modules/system_dlkm/modules.load))
BOARD_VENDOR_KERNEL_MODULES := $(wildcard $(KERNEL_PATH)/modules/vendor_dlkm/*.ko)
BOARD_VENDOR_KERNEL_MODULES_LOAD := $(strip $(shell cat $(KERNEL_PATH)/modules/vendor_dlkm/modules.load))
BOARD_VENDOR_RAMDISK_KERNEL_MODULES := $(wildcard $(KERNEL_PATH)/modules/vendor_ramdisk/*.ko)
BOARD_VENDOR_RAMDISK_KERNEL_MODULES_LOAD := $(strip $(shell cat $(KERNEL_PATH)/modules/vendor_ramdisk/modules.load))
BOARD_VENDOR_RAMDISK_RECOVERY_KERNEL_MODULES_LOAD := $(strip $(shell cat $(KERNEL_PATH)/modules/vendor_ramdisk/modules.load.recovery))

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

# Full A/B OTA: every partition LineageOS builds. Firmware (preloader, lk,
# tee, gz, scp, sspm, spmfw, md1img) is NOT shipped, as usual for LineageOS:
# both slots must already carry the same stock firmware (see README).
AB_OTA_PARTITIONS += \
    boot \
    vendor_boot \
    dtbo \
    vbmeta \
    vbmeta_system \
    vbmeta_vendor \
    system \
    system_ext \
    product \
    vendor \
    vendor_dlkm \
    odm_dlkm \
    system_dlkm

# Virtual A/B (compression.mk is inherited in the product makefile)
BOARD_SUPER_PARTITION_METADATA_DEVICE := super

# Dynamic / super partition
BOARD_SUPER_PARTITION_SIZE := 11811160064
# Same group name and size as stock ("main" -> main_a / main_b in metadata).
BOARD_SUPER_PARTITION_GROUPS := main
BOARD_MAIN_PARTITION_LIST := \
    system \
    system_ext \
    product \
    vendor \
    vendor_dlkm \
    odm_dlkm \
    system_dlkm
BOARD_MAIN_SIZE := 10200547328
# PRODUCT_USE_DYNAMIC_PARTITIONS is a PRODUCT variable and is already set (and
# made readonly) by lineage_clove_row_wifi.mk before BoardConfig.mk is parsed.
# Setting it here is a hard build error -- keep it in the product makefile only.
BOARD_BUILD_SUPER_IMAGE_BY_DEFAULT := false

# Static partition image sizes
BOARD_BOOTIMAGE_PARTITION_SIZE := 33554432
BOARD_VENDOR_BOOTIMAGE_PARTITION_SIZE := 67108864
# init_boot is BUILT but deliberately NOT in AB_OTA_PARTITIONS. On stock both
# init_boot partitions are all zeros: Lenovo carries the generic ramdisk
# (first-stage init + snapuserd) as the "init_boot" fragment of vendor_boot, and
# boot holds the kernel only. The build puts the generic ramdisk into boot.img
# unless it is building an init_boot image, so building one is what keeps
# boot.img kernel-only; leaving it out of the OTA keeps the partition as stock.
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
TARGET_COPY_OUT_VENDOR := vendor
BOARD_VENDORIMAGE_FILE_SYSTEM_TYPE := erofs

# The vendor partition still ships as a stock slot-A prebuilt (for now).
CLOVE_PREBUILT_PATH := vendor/lenovo/clove_row_wifi
BOARD_PREBUILT_VENDORIMAGE := $(CLOVE_PREBUILT_PATH)/images/vendor.img
TARGET_COPY_OUT_VENDOR_DLKM := vendor_dlkm
TARGET_COPY_OUT_ODM_DLKM := odm_dlkm
TARGET_COPY_OUT_SYSTEM_DLKM := system_dlkm
BOARD_USES_VENDOR_DLKMIMAGE := true
BOARD_USES_ODM_DLKMIMAGE := true
BOARD_USES_SYSTEM_DLKMIMAGE := true
BOARD_VENDOR_DLKMIMAGE_FILE_SYSTEM_TYPE := erofs
BOARD_ODM_DLKMIMAGE_FILE_SYSTEM_TYPE := erofs
BOARD_SYSTEM_DLKMIMAGE_FILE_SYSTEM_TYPE := erofs

# vendor_boot = [platform: stock, from PRODUCT_COPY_FILES] + [recovery: built
# LineageOS recovery] + [init_boot: stock prebuilt fragment], the same three
# fragments in the same order as stock.
#
# NOTE: this LK loads ALL vendor ramdisk fragments on every boot, including
# "recovery", and the device's real first-stage fstab is fstab.mt8786 -- which
# Lenovo ships in the recovery fragment. The prebuilt platform fragment therefore
# also carries first_stage_ramdisk/fstab.mt8786{,dm}; without them any recovery
# other than Lenovo's/TWRP's makes first-stage init panic ("failed to read
# default fstab for first stage mount"). See vendor/lenovo/clove_row_wifi/README.md.
BOARD_VENDOR_RAMDISK_FRAGMENTS := init_boot
BOARD_VENDOR_RAMDISK_FRAGMENT.init_boot.PREBUILT := $(CLOVE_PREBUILT_PATH)/images/vendor_ramdisk_init_boot.lz4
BOARD_VENDOR_RAMDISK_FRAGMENT.init_boot.MKBOOTIMG_ARGS := --ramdisk_type PLATFORM

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
# EXCEPTION to the rule above: vendor policy for LineageOS RECOVERY. Vendor
# policy built here never reaches the device's vendor partition (it is a stock
# prebuilt), but it IS compiled into the recovery ramdisk's sepolicy -- which is
# exactly where MediaTek's recovery boot-control HAL needs rules (labelled misc
# and whole-disk eMMC nodes, the boot-area switch ioctl). See sepolicy/recovery.
BOARD_VENDOR_SEPOLICY_DIRS += $(DEVICE_PATH)/sepolicy/recovery
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

BOARD_AVB_VBMETA_VENDOR := vendor
BOARD_AVB_VBMETA_VENDOR_KEY_PATH := external/avb/test/data/testkey_rsa4096.pem
BOARD_AVB_VBMETA_VENDOR_ALGORITHM := SHA256_RSA4096
BOARD_AVB_VBMETA_VENDOR_ROLLBACK_INDEX := 0
BOARD_AVB_VBMETA_VENDOR_ROLLBACK_INDEX_LOCATION := 4

# Inherit proprietary blob board config (generated by extract-files.py)
-include vendor/lenovo/clove_row_wifi/BoardConfigVendor.mk

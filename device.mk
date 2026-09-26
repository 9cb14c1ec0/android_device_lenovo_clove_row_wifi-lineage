#
# SPDX-FileCopyrightText: The LineageOS Project
# SPDX-License-Identifier: Apache-2.0
#
# STRATEGY: this port builds system, system_ext, product, boot (our own GKI
# kernel) and vendor_boot (LineageOS recovery). vendor, vendor_dlkm, odm_dlkm,
# system_dlkm, init_boot and the firmware are stock slot-A prebuilts from
# vendor/lenovo/clove_row_wifi, shipped unchanged in the full OTA -- no
# MediaTek BSP is available to rebuild them. Anything that would populate a
# rebuilt vendor image therefore does NOT belong here.
#

LOCAL_PATH := device/lenovo/clove_row_wifi

# -- A/B / update_engine -------------------------------------------------
# Only the partitions we actually build are listed for postinstall.
AB_OTA_POSTINSTALL_CONFIG += \
    RUN_POSTINSTALL_system=true \
    FILESYSTEM_TYPE_system=erofs \
    POSTINSTALL_PATH_system=system/bin/otapreopt_script \
    POSTINSTALL_OPTIONAL_system=true

# -- Shipping API level ----------------------------------------------------
# The stock device launched on Android 14 (ro.product.first_api_level=34) and
# its vendor is HIDL-based (Beanpod Keymaster 4.1 among others). This MUST be
# set: with PRODUCT_SHIPPING_API_LEVEL unset, main.mk installs NONE of the
# PRODUCT_PACKAGES_SHIPPING_API_LEVEL_* lists, so hwservicemanager is dropped
# (leaving a dangling /system/bin/hwservicemanager compat symlink). keystore2
# then never reaches Keymaster, vold blocks on keystore2 at late-fs, and the
# boot hangs on the LK splash forever.
PRODUCT_SHIPPING_API_LEVEL := 34

PRODUCT_PACKAGES += \
    otapreopt_script \
    update_engine \
    update_engine_sideload \
    update_verifier

# -- Dynamic partition / filesystem tooling (host + target) --------------
# lpmake is HOST-only; putting it in PRODUCT_PACKAGES is a hard build error
# ("Host modules should be in PRODUCT_HOST_PACKAGES"). It is not needed here
# anyway -- the build pulls it in as a host tool when it assembles a super
# image. The rest below all have real target variants and are useful on-device
# (fastbootd resizing logical partitions, recovery filesystem checks).
PRODUCT_PACKAGES += \
    lpdump \
    mkfs.erofs \
    fsck.erofs \
    make_f2fs \
    fsck.f2fs

# -- Kernel module path compat -------------------------------------------
# /system/lib/modules -> /system_dlkm/lib/modules is REQUIRED: vendor
# modules.dep references /system/lib/modules/rfkill.ko, and without the link
# cfg80211 never loads (Wi-Fi: "Unknown symbol cfg80211_*", no wlan0). The
# build creates it because BOARD_USES_SYSTEM_DLKMIMAGE is set (BoardConfig.mk);
# do not add a second copy here -- it collides with the build's own rule.

# -- SurfaceFlinger RenderEngine ---------------------------------------------
# Stock vendor sets debug.renderengine.backend=skiagl (non-threaded). With the
# LOS 22.2 (A15 QPR2) SurfaceFlinger that path is a use-after-free:
# renderScreenImpl() captures a raw RenderArea* in a lambda that, for a
# NON-threaded RenderEngine, is deferred onto the main thread after
# captureScreenshot() has already destroyed the RenderArea. Every screenshot /
# task snapshot then SIGSEGVs SurfaceFlinger in ScreenCaptureOutput, which
# restarts system_server ("reboots" when opening e.g. Settings > Reset options).
# The threaded backend runs present() synchronously and is the AOSP default.
# Product props load after vendor, so this overrides the stock value.
PRODUCT_PRODUCT_PROPERTIES += \
    debug.renderengine.backend=skiaglthreaded

# -- Recovery -----------------------------------------------------------------
# ro.hardware is mt8786; stock ships the same file under both platform names.
PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/rootdir/etc/init.recovery.mt8786.rc:$(TARGET_COPY_OUT_RECOVERY)/root/init.recovery.mt8786.rc \
    $(LOCAL_PATH)/rootdir/etc/init.recovery.mt8786.rc:$(TARGET_COPY_OUT_RECOVERY)/root/init.recovery.mt6768.rc

# -- Overlays ------------------------------------------------------------
DEVICE_PACKAGE_OVERLAYS += $(LOCAL_PATH)/overlay

# -- Soong namespace -----------------------------------------------------
PRODUCT_SOONG_NAMESPACES += $(LOCAL_PATH)

#
# Intentionally NOT here, and why:
#
#   * Vendor HAL services (boot@1.2, health@2.1, sensors, wifi, audio, ...).
#     The stock vendor partition ships 47 HAL service binaries plus 38 VINTF
#     manifest fragments. Building LineageOS copies would put them on a vendor
#     image we never produce.
#
#   * $(call inherit-product, vendor/lenovo/clove_row_wifi/...-vendor.mk).
#     extract-files.py can generate that tree, and proprietary-files.txt lists
#     all 2291 stock blobs, but under this strategy the blobs already ship on
#     the retained stock vendor partition. Inherit it only if the port later
#     switches to rebuilding vendor, or if a specific blob must be relocated
#     to the system side.
#

# First-stage fstab (vendor_boot platform ramdisk). LK passes
# androidboot.hardware=mt8786, so first-stage init reads fstab.mt8786; Lenovo
# ships the same file under all three names. fstab.mt8786dm is the variant with
# the dm-userdata (lenovobackup) layout.
PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/rootdir/etc/fstab.mt6768:$(TARGET_COPY_OUT_VENDOR_RAMDISK)/first_stage_ramdisk/fstab.mt6768 \
    $(LOCAL_PATH)/rootdir/etc/fstab.mt6768:$(TARGET_COPY_OUT_VENDOR_RAMDISK)/first_stage_ramdisk/fstab.mt8786 \
    $(LOCAL_PATH)/rootdir/etc/fstab.mt8786dm:$(TARGET_COPY_OUT_VENDOR_RAMDISK)/first_stage_ramdisk/fstab.mt8786dm

# -- Stock slot-A prebuilts (vendor_boot platform ramdisk) --------------------
$(call inherit-product, vendor/lenovo/clove_row_wifi/clove_row_wifi-prebuilts.mk)

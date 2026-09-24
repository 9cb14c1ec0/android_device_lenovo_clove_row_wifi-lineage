#
# SPDX-FileCopyrightText: The LineageOS Project
# SPDX-License-Identifier: Apache-2.0
#
# STRATEGY: this port builds ONLY system, system_ext and product.
# vendor, vendor_dlkm, odm_dlkm and system_dlkm are kept from stock firmware,
# because Lenovo released no kernel source and no MediaTek BSP is available.
# Anything that would populate a vendor image therefore does NOT belong here.
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
# See Android.bp: /system/lib/modules -> /system_dlkm/lib/modules (Wi-Fi).
PRODUCT_PACKAGES += \
    clove_system_lib_modules_symlink

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
#   * fstab.mt6768 as a vendor/ramdisk copy. First-stage mount is driven by the
#     fstab inside the STOCK vendor ramdisk. rootdir/etc/fstab.mt6768 is kept
#     in this tree only as TARGET_RECOVERY_FSTAB and as documentation of the
#     stock layout; installing our own copy would either be ignored or fight
#     the stock first-stage mount.
#
#   * $(call inherit-product, vendor/lenovo/clove_row_wifi/...-vendor.mk).
#     extract-files.py can generate that tree, and proprietary-files.txt lists
#     all 2291 stock blobs, but under this strategy the blobs already ship on
#     the retained stock vendor partition. Inherit it only if the port later
#     switches to rebuilding vendor, or if a specific blob must be relocated
#     to the system side.
#

#
# SPDX-FileCopyrightText: The LineageOS Project
# SPDX-License-Identifier: Apache-2.0
#

# Inherit from those products. Most specific first.
$(call inherit-product, $(SRC_TARGET_DIR)/product/core_64_bit.mk)
$(call inherit-product, $(SRC_TARGET_DIR)/product/aosp_base.mk)

# Virtual A/B with compression (stock uses VAB snapshots)
$(call inherit-product, $(SRC_TARGET_DIR)/product/virtual_ab_ota/compression.mk)

# Inherit from clove_row_wifi device
$(call inherit-product, device/lenovo/clove_row_wifi/device.mk)

# Inherit some common Lineage stuff — Wi-Fi-only tablet
$(call inherit-product, vendor/lineage/config/common_full_tablet_wifionly.mk)

PRODUCT_DEVICE := clove_row_wifi
PRODUCT_NAME := lineage_clove_row_wifi
PRODUCT_BRAND := Lenovo
PRODUCT_MODEL := TB305FU
PRODUCT_MANUFACTURER := LENOVO

PRODUCT_GMS_CLIENTID_BASE := android-lenovo

PRODUCT_USE_DYNAMIC_PARTITIONS := true

# Match the stock build fingerprint so the vendor/TEE (Beanpod) sees the
# firmware it expects. Stock: Android 15 / AP3A.240905.015.A2.
# PRODUCT_BUILD_PROP_OVERRIDES keys must exist in Soong's product_config.json.
# The make-style names (TARGET_DEVICE, PRODUCT_NAME, PRIVATE_BUILD_DESC) are a
# pre-Android-14 idiom and are rejected outright:
#   Key "TARGET_DEVICE" isn't a valid prop override
# Valid keys here are Soong-style (DeviceName, ProductModel, ProductBrand...),
# and PRODUCT_DEVICE/MODEL/BRAND above already set those correctly, so no
# override block is needed. BUILD_FINGERPRINT alone pins the fingerprint.
BUILD_FINGERPRINT := Lenovo/TB305FU/TB305FU:15/AP3A.240905.015.A2/__ROW:user/release-keys

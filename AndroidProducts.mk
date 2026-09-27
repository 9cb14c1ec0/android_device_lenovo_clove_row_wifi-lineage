#
# SPDX-FileCopyrightText: The LineageOS Project
# SPDX-License-Identifier: Apache-2.0
#

PRODUCT_MAKEFILES := \
    $(LOCAL_DIR)/lineage_clove_row_wifi.mk

# LineageOS 22.2 uses the Android 14+ three-part lunch format:
#   <product>-<release config>-<variant>
# The release config is `bp1a` (LineageOS's own).
COMMON_LUNCH_CHOICES := \
    lineage_clove_row_wifi-bp1a-user \
    lineage_clove_row_wifi-bp1a-userdebug \
    lineage_clove_row_wifi-bp1a-eng

#
# SPDX-FileCopyrightText: The LineageOS Project
# SPDX-License-Identifier: Apache-2.0
#

PRODUCT_MAKEFILES := \
    $(LOCAL_DIR)/lineage_clove_row_wifi.mk

# LineageOS 22.2 uses the Android 14+ three-part lunch format:
#   <product>-<release config>-<variant>
# The release config must be `bp1a` (LineageOS's own, inheriting ap4a): it
# resolves BOARD_API_LEVEL to 202404, which makes PLATFORM_SEPOLICY_VERSION
# exactly match the stock vendor's plat_sepolicy_vers.txt (202404), so no
# sepolicy compatibility mapping is needed. Verified with get_build_var.
COMMON_LUNCH_CHOICES := \
    lineage_clove_row_wifi-bp1a-user \
    lineage_clove_row_wifi-bp1a-userdebug \
    lineage_clove_row_wifi-bp1a-eng

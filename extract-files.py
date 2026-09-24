#!/usr/bin/env -S PYTHONPATH=../../../tools/extract-utils python3
#
# SPDX-FileCopyrightText: The LineageOS Project
# SPDX-License-Identifier: Apache-2.0
#
# Extracts proprietary blobs for clove_row_wifi from a stock firmware source.
#
# IMPORTANT: get the source images with ./pull-stock-images.sh (live adb pull
# from the merged Virtual A/B mapper nodes on a TWRP-booted device). Do NOT
# use an lpunpack of super.bin: that gives the pre-snapshot BASE image, whose
# COW-updated inodes read back as zero, so fsck.erofs dies with
# "bogus i_mode (0)" and /vendor/etc + /vendor/firmware are unreadable.
#
#   ./pull-stock-images.sh stock_images
#   for p in vendor vendor_dlkm odm_dlkm system_dlkm; do \
#       fsck.erofs --extract=extracted/$p stock_images/${p}_a.img; done
#   ./extract-files.py extracted

from extract_utils.fixups_blob import (
    blob_fixup,
    blob_fixups_user_type,
)
from extract_utils.main import (
    ExtractUtils,
    ExtractUtilsModule,
)

namespace_imports = [
    "hardware/mediatek",
    "vendor/mediatek",
]

# Blob fixups discovered during bring-up go here (see TB-8505F for the pattern:
# libbase_shim / libunwindstack_shim injection for legacy MTK blobs). Populate
# as the first boot surfaces missing-symbol / dlopen failures.
blob_fixups: blob_fixups_user_type = {}

module = ExtractUtilsModule(
    'clove_row_wifi',
    'lenovo',
    blob_fixups=blob_fixups,
    namespace_imports=namespace_imports,
)

if __name__ == '__main__':
    utils = ExtractUtils.device(module)
    utils.run()

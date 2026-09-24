# LineageOS 22.2 for Lenovo Tab One (TB305FU / clove_row_wifi)

Experimental LineageOS 22.2 (Android 15) device tree for the Lenovo Tab One
Wi-Fi (`TB305FU`, device `clove_row_wifi`), a MediaTek MT6768/MT8786 tablet
with a GKI 6.6 kernel.

**Status: boots to the LineageOS home/lock screen with SELinux enforcing, on an
existing encrypted `/data`. Wi-Fi works. Much is still untested — see
[Status](#status).** This is a bring-up tree, not a daily-driver release.

The companion TWRP device tree for the same tablet is
[android_device_lenovo_clove_row_wifi](https://github.com/9cb14c1ec0/android_device_lenovo_clove_row_wifi).
Several findings here (crypto stack, AVB/LK behaviour, safety rules) come from
that port.

## Why this is a prebuilt-kernel / stock-vendor port

Lenovo has **not** released kernel source for this device. Consequences that
shape every decision here:

- The **stock GKI 6.6 kernel `Image`, `.dtb` and `dtbo.img` ship as
  prebuilts** (`prebuilt/`). The kernel and its modules cannot be rebuilt.
- `vendor`, `vendor_dlkm`, `odm_dlkm` and `system_dlkm` are **kept from stock
  firmware**. LineageOS builds only `system`, `system_ext` and `product`,
  which are repacked into the stock A/B dynamic `super` layout.
- Because no vendor image is produced, the tree deliberately does **not** build
  vendor HALs, does not set `BOARD_VENDOR_SEPOLICY_DIRS`, does not include
  MediaTek's `sepolicy_vndr/SEPolicy.mk`, and does not inherit the generated
  `vendor/lenovo/clove_row_wifi` blob makefile. `device.mk` documents each
  omission. `proprietary-files.txt` remains the HAL/VINTF reference, and the
  starting point if the port ever switches to rebuilding vendor.
- Userdata is **FBE v2 + metadata (dm-default-key) encryption**, with keys
  **hardware-bound to the Beanpod (Microtrust) Keymaster 4.1 TEE**. Decryption
  relies on the stock vendor crypto stack, which this port keeps.
- The stock vendor declares **VINTF `target-level="6"`** (Android 12 FCM).
  `configs/vintf/manifest.xml` is the stock file verbatim — do not
  "modernise" that value; the framework has to stay compatible with FCM 6.

## Device facts

| | |
| --- | --- |
| SoC | MediaTek MT6768 / MT8786 |
| Kernel | GKI `6.6.82-android15` (no source) |
| Stock OS | Android 15 / ZUI 17, `AP3A.240905.015.A2` |
| Fingerprint | `Lenovo/TB305FU/TB305FU:15/AP3A.240905.015.A2/__ROW:user/release-keys` |
| Launch API level | 34 (`ro.product.first_api_level`) |
| Partitions | A/B, Virtual A/B snapshots, dynamic `super` (11811160064 B) |
| RO filesystems | EROFS (system/product/vendor/*dlkm) |
| Userdata | F2FS, FBE v2 `aes-256-xts:aes-256-cts:v2`, metadata `dm-default-key` |
| Boot image | header v4, 4 KiB pages, DTB in bootimg |
| TEE / Keymaster | Beanpod HIDL Keymaster 4.1 on hwbinder |
| VINTF target-level | **6** (FCM 6 / Android 12) |
| Vendor sepolicy | 202404 (same as LineageOS 22.2 platform — no mapping shim) |
| Wi-Fi | MediaTek connsys, `wlan_drv_gen4m_6768` |

## Layout

```
device/lenovo/clove_row_wifi/
  BoardConfig.mk              board geometry, partitions, AVB, filesystems
  lineage_clove_row_wifi.mk   product definition (wifi-only tablet)
  device.mk                   packages, props, A/B; documents each omission
  Android.bp                  soong namespace + /system/lib/modules symlink
  AndroidProducts.mk          lunch combos
  system.prop / vendor.prop   runtime props
  rootdir/etc/fstab.mt6768    unified fstab (stock-matching, reference)
  configs/vintf/              stock device manifest + matrix + 38 fragments
  sepolicy/                   system-side only; see sepolicy/README.md
  prebuilt/kernel             stock GKI Image (gzip)
  prebuilt/dtb/stock.dtb      stock device tree blob
  prebuilt/dtbo.img           stock DTBO
  extract-files.py            blob extraction (extract-utils)
  setup-makefiles.py          regenerate vendor makefiles
  proprietary-files.txt       2291 stock blobs (reference)
  pull-stock-images.sh        read-only live adb pull of stock partitions
  gen-proprietary-files.py    regenerate the blob list from an extract root
```

## Status

| Area | State |
| --- | --- |
| Build (`systemimage systemextimage productimage`) | works |
| Boot to lock screen / home, SELinux enforcing | **works** |
| Existing encrypted `/data` (stock Beanpod crypto) | **decrypts** |
| Display, SurfaceFlinger, screenshots/transitions | works |
| Wi-Fi scan (2.4 + 5 GHz) | **works** |
| Wi-Fi connect | untested |
| Bluetooth | kernel modules load; untested |
| Audio, camera, sensors, GPS | untested |
| Suspend / battery drain | untested |
| Clean install (formatted `/data`) | untested — only tested over existing stock `/data` |

Booting over an existing stock `/data` is effectively a dirty flash: stock apps
may have newer databases than LineageOS understands. One was seen —
`DownloadProvider` crash-looping on `Can't downgrade database from version 116
to 114` — fixed by clearing that provider's data
(`pm clear com.android.providers.downloads`).

## Build

```bash
export ALLOW_MISSING_DEPENDENCIES=true
source build/envsetup.sh
lunch lineage_clove_row_wifi-bp1a-userdebug
mka systemimage systemextimage productimage vbmetasystemimage vbmetaimage
```

The `bp1a` release config is required (Android 14+ three-part lunch format).
Do **not** use `mka bacon`: it packages an OTA zip that expects boot and vendor
images this port never builds.

After changing any partition-layout variable (`TARGET_COPY_OUT_*`) or removing
files from `PRODUCT_COPY_FILES`, run `m installclean` first. Incremental builds
report success while shipping stale files from `out/`.

## Assemble `super` and flash

The stock `vendor`/`*_dlkm` images must come from the device itself — see
[the blob gotcha](#gotcha-never-lpunpack-superbin). With the stock images in
`stock/` (e.g. from `./pull-stock-images.sh stock`):

```bash
OUT=out/target/product/clove_row_wifi
sz() { stat -c %s "$1"; }
lpmake --device-size 11811160064 --metadata-size 65536 --metadata-slots 3 \
  --super-name super --virtual-ab --block-size 4096 --alignment 1048576 \
  --group main_a:10200547328 \
  --partition system_a:readonly:$(sz $OUT/system.img):main_a         --image system_a=$OUT/system.img \
  --partition system_ext_a:readonly:$(sz $OUT/system_ext.img):main_a --image system_ext_a=$OUT/system_ext.img \
  --partition product_a:readonly:$(sz $OUT/product.img):main_a       --image product_a=$OUT/product.img \
  --partition vendor_a:readonly:$(sz stock/vendor_a.img):main_a            --image vendor_a=stock/vendor_a.img \
  --partition vendor_dlkm_a:readonly:$(sz stock/vendor_dlkm_a.img):main_a  --image vendor_dlkm_a=stock/vendor_dlkm_a.img \
  --partition odm_dlkm_a:readonly:$(sz stock/odm_dlkm_a.img):main_a        --image odm_dlkm_a=stock/odm_dlkm_a.img \
  --partition system_dlkm_a:readonly:$(sz stock/system_dlkm_a.img):main_a  --image system_dlkm_a=stock/system_dlkm_a.img \
  --sparse --output super.img
```

Then, from the **bootloader** (`adb reboot bootloader`), after confirming
`fastboot getvar product` is `clove_row_wifi` and `current-slot` is `a`:

```bash
fastboot flash super super.img
fastboot flash vbmeta_system $OUT/vbmeta_system.img
fastboot flash vbmeta $OUT/vbmeta.img
fastboot set_active a
fastboot reboot
```

`vbmeta` is built with `--flags 3` (verification disabled) and signed with the
AVB test key. The stock LK rejects that; the device must already run the
patched LK from the TWRP port.

**Slot retries:** every failed boot uses one of slot A's retries. At zero, LK
logs `[AB] no valid slot!` and sits on the Lenovo splash forever — which looks
exactly like a boot hang. Check `fastboot getvar slot-unbootable:a`; reset with
`fastboot set_active a` (getvars are cached until `fastboot reboot bootloader`).

## Fixes that were required to boot (do not reintroduce)

1. **`TARGET_COPY_OUT_VENDOR := vendor` is mandatory** even though no vendor
   image is built. Left unset, the build defaults it to `system/vendor` and
   makes `/vendor` a *symlink* in `system.img`. A partition can't be mounted
   on a symlink, so first-stage init dies:
   `Kernel panic - not syncing: Attempted to kill init! exitcode=0x00007f00`.
2. **`PRODUCT_SHIPPING_API_LEVEL := 34`.** With it unset, `main.mk` installs
   none of the `PRODUCT_PACKAGES_SHIPPING_API_LEVEL_*` lists, so
   `hwservicemanager` is dropped. keystore2 then can't reach the HIDL Beanpod
   Keymaster, `vold` blocks at `late-fs`, and the device sits on the LK splash
   forever with `servicemanager` retrying `IKeystoreService` every second.
3. **`/system/lib/modules -> /system_dlkm/lib/modules`** (`Android.bp`). The
   build only creates this link when it also builds `system_dlkm`, which this
   port keeps from stock. Vendor `modules.dep` references
   `/system/lib/modules/rfkill.ko`, so without the link `cfg80211` never loads
   and Wi-Fi fails with `Unknown symbol cfg80211_*` (no `wlan0`). Bluetooth,
   NFC and `mac80211` modules depend on the same path.
4. **`debug.renderengine.backend=skiaglthreaded`** (product prop). Stock vendor
   sets the non-threaded `skiagl`. With LineageOS 22.2's SurfaceFlinger that
   path is a use-after-free: `renderScreenImpl()` captures a raw `RenderArea*`
   in a lambda that, for a non-threaded RenderEngine, runs on the main thread
   after the `RenderArea` has been destroyed. Every screenshot or window
   transition then SIGSEGVs SurfaceFlinger in `ScreenCaptureOutput`, which
   restarts `system_server` (looks like a reboot). Product props load after
   vendor, so this overrides the stock value.

### Build-config bugs (do not reintroduce)

1. `PRODUCT_USE_DYNAMIC_PARTITIONS` set in **both** `BoardConfig.mk` and the
   product makefile — it is a product variable and readonly by the time
   BoardConfig is parsed. Product makefile only.
2. `TARGET_COPY_OUT_VENDOR_DLKM` / `ODM_DLKM` / `SYSTEM_DLKM` set — that tells
   the build to *produce* those images. They are kept from stock; leave unset.
3. **No `:=` value in this tree may be quoted.** Make keeps quotes literally,
   so `BOARD_EROFS_COMPRESSOR := "lz4hc,9"` broke Soong's variables JSON, and
   `TARGET_RECOVERY_PIXEL_FORMAT := "BGRA_8888"` broke
   `soong.<product>.extra.variables` — only generated ~89% into a full build.
4. `lpmake` in `PRODUCT_PACKAGES` — it is host-only.
5. `PRODUCT_BUILD_PROP_OVERRIDES` with make-style keys (`TARGET_DEVICE`,
   `PRODUCT_NAME`, ...) — Soong rejects them. Copied from a LineageOS 23 tree;
   idioms don't necessarily port across versions.
6. `ro.secure` / `ro.adb.secure` in `system.prop` — the build variant already
   assigns them and `gen_build_prop` fails on duplicate assignments.

## Debugging without a display or adb

When a boot stalls on the LK splash there is no adb and no display.
`/sys/fs/pstore` is **not** useful on this device: LK's kedump keeps restoring
one stale ramoops record, so the "last kernel log" never changes. What worked
during bring-up was a temporary init service (in a permissive userdebug-only
SELinux domain) that streamed `/proc/kmsg`, logcat, `getprop` and `ps` into
`/metadata`, which is mounted by first-stage init and readable from TWRP.
`/metadata` is only 16 MB and holds the metadata-encryption key, so any such
recorder must be size-capped.

## Gotcha: never lpunpack super.bin

This device runs Virtual A/B snapshots, and the stock firmware has live COW
devices (`vendor_a-cow`, `system_a-cow`, ...). An `lpunpack` of a `super`
dump returns the **pre-snapshot base image**: every inode in a COW-updated
region reads back as zero.

- `fsck.erofs --extract` aborts: `bogus i_mode (0) @ nid 9142144`
- A loop mount succeeds, but `/vendor/etc` and `/vendor/firmware` return EIO
- **Both slots fail at the identical nid** — the damage is in the unpack

Read the merged view from the live device instead:
`/dev/block/mapper/<part>_<slot>`. `pull-stock-images.sh` does this over adb
(TWRP) and verifies size + sha256. It is read-only.

## Security patch level

The stock TEE is configured at security patch 2026-05-05, and LineageOS 22.2
advertises an older level. There was a concern this could break `/data`
decryption through rollback protection. In practice the first boot decrypted
the existing stock `/data` without issue.

## Safety rules

- **Never** `fastboot -w`, format `/data`, or format `/metadata` as a
  troubleshooting step. Keys are hardware-bound; wiping is unrecoverable and
  does not help debugging.
- Flash experiments to **slot A only**.
- Always confirm `product=clove_row_wifi` and `current-slot=a` before flashing.
- Preserve Lenovo's stock kernel, DTB, DTBO and vendor partitions.

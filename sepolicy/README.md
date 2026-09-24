# SELinux policy for clove_row_wifi

## There is deliberately almost nothing here

This port keeps the **stock vendor partition**, which already carries a
complete policy in `/vendor/etc/selinux/`:

| File | Size | Role |
| --- | --- | --- |
| `vendor_sepolicy.cil` | 1.3 MB | all vendor types and rules |
| `plat_pub_versioned.cil` | 387 KB | versioned public platform types |
| `precompiled_sepolicy` | 1.3 MB | prebuilt binary policy |
| `vendor_file_contexts` | 111 KB | vendor file labelling |
| `vendor_property_contexts` | 46 KB | vendor property labelling |
| `plat_sepolicy_vers.txt` | 7 B | **202404** |

`202404` is the Android 15 platform policy version — the same version
LineageOS 22.2 builds — so vendor and platform match exactly and **no
compatibility mapping shim is needed**.

All Microtrust/Beanpod TEE types already exist in the stock vendor policy:
`teei_client_device`, `teei_control_file`, `teei_data_file`, `teei_hal_thh`,
`teei_hal_capi`, `teei_hal_tui`, `teei_hal_ifaa`, `tee_exec`,
`hal_keymaster_default`, and the matching `file_contexts` entries for
`teei_daemon`, `android.hardware.keymaster@4.1-service.beanpod` and
`android.hardware.gatekeeper-service.beanpod`.

So: **do not re-declare vendor types here, and do not set
`BOARD_VENDOR_SEPOLICY_DIRS`.** No vendor image is built.

## What the TWRP port's sepolicy is, and why it is NOT ported

`../../../../twrp-14.1/device/lenovo/clove_row_wifi/sepolicy/recovery.te`
exists to let the **recovery domain impersonate** `servicemanager`,
`hwservicemanager` and `keystore2` inside TWRP, where everything runs as
`u:r:recovery:s0`. Those allows (`binder set_context_mgr`, adding
`service_manager_service`, `mlstrustedsubject`, ...) are meaningful only in
recovery.

In a normal Android boot each of those services runs in its own upstream
domain with policy that already exists. Copying `recovery.te` rules into a
LineageOS build would grant a domain that is not even used at boot, and some
would trip platform neverallows. **The TWRP policy is a source of findings,
not a source of rules.**

What *does* carry over from the TWRP work is knowledge:

- Beanpod Keymaster is **HIDL 4.1 on hwbinder**, so `hwservicemanager` must
  run; it does **not** use VendorBinder, so `vndservicemanager` is not needed.
- The HAL needs vendor `libc++` on its library path.
- There must be exactly **one** `teei_daemon` for the whole boot; starting a
  second one, or killing it, wedges TEEI on `teei_cpus_read_lock`.

## `private/`

`SYSTEM_EXT_PRIVATE_SEPOLICY_DIRS` points at `private/`. Add LineageOS
system-side policy here only when a real denial requires it. Keep it empty
until first boot produces actual AVCs.

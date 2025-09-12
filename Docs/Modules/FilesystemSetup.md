### Module: FilesystemSetup

Purpose: Choose and record filesystem strategy for the stable installer.

Stable behavior:
- ZFS and Btrfs paths are not implemented on stable; both fall back to ext4
- Records resulting filesystem in `FILESYSTEM_CREATED` and `CURRENT_FILESYSTEM`

Outputs:
- `FILESYSTEM_CREATED=ext4`, `CURRENT_FILESYSTEM=ext4`

Notes:
- Future branches may enable advanced filesystems; stable prioritizes safety and compatibility.


### Module: CoreInstallation

Purpose: Install the base Arch system and core packages, and create the primary user.

Stable behavior:
- Installs `base`, `linux-zen` (or `linux` if not selected), `linux-firmware`, `networkmanager`, `zsh`, `sudo`, `vim`
- Generates `fstab`, sets hostname, timezone, locale, and enables NetworkManager
- Creates user with shell `/bin/zsh` and configures wheel sudoers include

Inputs:
- `USE_ZEN_KERNEL`, `USERNAME`, `HOSTNAME`, `TIMEZONE`, `DEFAULT_LOCALE`

Notes:
- Passwords are set non‑interactively if captured earlier by `Install_Arch.sh`.


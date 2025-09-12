# TDP Configuration Module
# ASUS ROG Flow Z13 (2025) - Configurable TDP and Power Management


tdp_configuration_setup() {
	PrintHeader "TDP Configuration Setup"

	# Install core tools using parent helpers (no custom functions inside chroot subshells)
	InstallPackageGroupWithVerification cpupower acpi-call-dkms msr-tools chroot || true
	InstallPackageGroupWithVerification powertop turbostat i7z chroot || true

	# Bake numeric constants into the generated script at creation time
	local eff="$TDP_EFFICIENT"
	local aiw="$TDP_AI"
	local game="$TDP_GAMING"

	local out_path="/mnt$TDP_MANAGER_PATH"
	mkdir -p "$(dirname "$out_path")"
	cat > "$out_path" <<EOF
#!/bin/bash
# TDP Manager for ASUS ROG Flow Z13 (2025) with Dynamic Power Management

set -e

detect_charger_wattage() {
	local max_tdp=7
	if [ -f /sys/class/power_supply/usb/current_max ]; then
		local current_max=\$(cat /sys/class/power_supply/usb/current_max 2>/dev/null || echo "0")
		local voltage=\$(cat /sys/class/power_supply/usb/voltage_now 2>/dev/null || echo "5000000")
		local wattage=\$((current_max * voltage / 1000000000))
		if [ "\$wattage" -ge 100 ]; then
			max_tdp=120
		elif [ "\$wattage" -ge 65 ]; then
			max_tdp=100
		elif [ "\$wattage" -ge 45 ]; then
			max_tdp=65
		elif [ "\$wattage" -ge 20 ]; then
			max_tdp=45
		else
			max_tdp=7
		fi
	fi
	echo "\$max_tdp"
}

set_tdp() {
	local requested_tdp=\$1
	local max_tdp=\$(detect_charger_wattage)
	if [ "\$requested_tdp" -gt "\$max_tdp" ]; then
		echo "Requested TDP \${requested_tdp}W exceeds charger limit \${max_tdp}W. Limiting to \${max_tdp}W."
		requested_tdp="\$max_tdp"
	fi
	local tdp_mw=\$((requested_tdp * 1000))
	echo "Setting TDP to \${requested_tdp}W (\${tdp_mw}mW) - max available: \${max_tdp}W..."
	if command -v ryzenadj &> /dev/null; then
		ryzenadj --stapm-limit="\$tdp_mw" --fast-limit="\$tdp_mw" --slow-limit="\$tdp_mw"
	fi
	echo "TDP set to \${requested_tdp}W successfully (charger limit: \${max_tdp}W)"
}

case "\$1" in
	efficient)
		set_tdp "$eff"
		echo "Efficient power profile activated (${eff}W TDP)"
		;;
	ai)
		set_tdp "$aiw"
		echo "AI power profile activated (${aiw}W TDP)"
		;;
	gaming)
		set_tdp "$game"
		echo "Gaming power profile activated (${game}W TDP)"
		;;
	max)
		local max_tdp=\$(detect_charger_wattage)
		set_tdp "\$max_tdp"
		echo "Maximum power profile activated (\${max_tdp}W TDP - limited by charger)"
		;;
	custom)
		local custom_tdp=""
		local attempts=0
		local max_attempts=3
		while [[ \$attempts -lt \$max_attempts ]]; do
			read -p "Enter custom TDP value (7-120W): " custom_tdp
			if [[ "\$custom_tdp" =~ ^[0-9]+$ ]] && [[ \$custom_tdp -ge 7 && \$custom_tdp -le 120 ]]; then
				set_tdp \$custom_tdp
				echo "Custom TDP profile activated (\${custom_tdp}W TDP)"
				break
			else
				echo "Invalid TDP value. Please enter a number between 7 and 120."
				((attempts++))
				if [[ \$attempts -lt \$max_attempts ]]; then
					echo "Please try again (\$((max_attempts - attempts)) attempts remaining)"
				fi
			fi
		done
		if [[ \$attempts -eq \$max_attempts ]]; then
			echo "Maximum attempts reached. Using default AI profile (${aiw}W)."
			set_tdp "$aiw"
		fi
		;;
	status)
		local max_tdp=\$(detect_charger_wattage)
		echo "Charger detected: \${max_tdp}W maximum TDP available"
		;;
	*)
		echo "Usage: \$0 {efficient|ai|gaming|max|custom|status}"
		exit 1
		;;
esac
EOF
	chmod +x "$out_path"

	PrintStatus "TDP configuration setup completed"
}

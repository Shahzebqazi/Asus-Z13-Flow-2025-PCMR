# ASUS ROG Flow Z13 Arch Linux Installation Flowchart

## Installation Process Flow

**Note:** This flowchart references files in the `Docs/` directory. All installation guides are now organized under `Docs/` for better structure.

```mermaid
graph TD
    A[📖 Read Docs/Instructions.md] --> B{Have Dedicated SSD?}
    B -->|Yes| C[🚀 Linux-Only Installation<br/>5-6s boot time]
    B -->|No| D[💾 Backup Windows System]
    
    C --> C1[Backup Windows to External]
    C1 --> C2[Wipe Entire SSD]
    C2 --> C3[Use systemd-boot]
    C3 --> F
    
    D --> E[🛡️ Create Recovery Media]
    E --> F[🔧 Shrink Windows Partition]
    F --> G[✅ Verify Windows Still Boots]
    G --> H[💿 Boot Arch Linux USB]
    
    H --> I{Choose Installation Method}
    I -->|🤖 Automated| J[Run curl command<br/>pcmr.sh]
    I -->|📋 Manual| K[Follow Docs/Instructions.md]
    
    J --> L[⚙️ Configure Options]
    K --> L
    
    L --> M[Desktop Environment?]
    M --> M1[Omarchy - Tiling WM (Default)]
    M --> M2[XFCE - User Friendly]
    M --> M3[i3 - Tiling WM]
    M --> M4[GNOME - Full DE]
    M --> M5[KDE - Feature Rich]
    M --> M6[Minimal - No GUI]
    
    M1 --> N
    M2 --> N
    M3 --> N
    M4 --> N
    M5 --> N
    M6 --> N
    
    N[🎮 Gaming Setup?]
    N -->|Yes| N1[Install Steam + Proton]
    N -->|No| O
    N1 --> O
    
    O[⚡ Power Management]
    O --> O1[Configure AMD Strix Halo TDP<br/>7W-120W Dynamic Control]
    O1 --> O2[Charger Detection<br/>Auto-adjust TDP limits]
    O2 --> P
    
    P[📸 ZFS Snapshots?]
    P -->|Yes| P1[Setup ZFS Auto-Snapshots]
    P -->|No| Q
    P1 --> Q
    
    Q[🔧 Install Arch Linux<br/>with Zen Kernel]
    Q --> R[Apply Z13 Hardware Fixes]
    R --> R1[Wi-Fi Stability Fix<br/>MediaTek MT7925e]
    R --> R2[Touchpad Detection<br/>hid_asus driver]
    R --> R3[Screen Flicker Fix<br/>Intel PSR disabled]
    R --> R4[Power Management<br/>asusctl + TLP]
    R --> R5[Zen Kernel Benefits<br/>Low latency + Gaming]
    
    R1 --> S
    R2 --> S
    R3 --> S
    R4 --> S
    R5 --> S
    
    S[🔄 Test Dual-Boot]
    S --> T{Boot Test Results}
    T -->|✅ Success| U[🎉 Complete Setup]
    T -->|❌ Issues| V[🔧 Troubleshoot]
    
    V --> V1[Check GRUB Config]
    V --> V2[Verify Partitions]
    V --> V3[Test Hardware]
    V1 --> W{Fixed?}
    V2 --> W
    V3 --> W
    
    W -->|Yes| U
    W -->|No| X[📞 Seek Help]
    
    U --> Y[🚀 Enjoy Arch Linux!]
    
    style A fill:#e1f5fe
    style B fill:#fff3e0
    style C fill:#e8f5e8
    style J fill:#f3e5f5
    style U fill:#e8f5e8
    style U1 fill:#fff3e0
    style U2 fill:#e8f5e8
    style U3 fill:#e8f5e8
    style U4 fill:#e8f5e8
    style Y fill:#e8f5e8
    style V fill:#ffebee
    style X fill:#ffebee
```

## Decision Points Explained

### 1. **Dedicated SSD Choice**
- **Yes**: Single-OS installation with optimal performance
- **No**: Dual-boot setup preserving Windows

### 2. **Installation Method**
- **Automated**: Beginner-friendly script with prompts
- **Manual**: Full control over every step

### 3. **Desktop Environment Options**
- **i3**: Minimal, keyboard-driven, excellent for productivity
- **GNOME**: Modern, touch-friendly, good tablet mode
- **KDE**: Highly customizable, Windows-like
- **Minimal**: Command-line only, maximum performance

### 4. **Gaming Setup**
- Installs Steam, Proton, GameMode, MangoHUD
- Enables multilib repository for 32-bit games
- Configures AMD GPU drivers

### 5. **Power Management**
- Configures asusctl for ASUS-specific features
- Sets up TLP for battery optimization
- Enables 7W-54W TDP control

## Boot Time Comparison

```mermaid
graph LR
    A[Boot Time Comparison] --> B[Linux-only + systemd-boot: 5-6s]
    A --> C[Linux-only + GRUB: 7-8s]
    A --> D[Dual-boot + GRUB: 10-11s]
    A --> E[Windows 11: 25-30s]
    
    style B fill:#e8f5e8
    style C fill:#fff9c4
    style D fill:#fff3e0
    style E fill:#ffebee
```

## Hardware Fix Pipeline

```mermaid
graph TD
    A[Z13 Hardware Issues] --> B[Wi-Fi Instability]
    A --> C[Touchpad Detection]
    A --> D[Screen Flickering]
    A --> E[Audio Glitches]
    A --> F[Power Management]
    
    B --> B1[Disable ASPM<br/>mt7925e module]
    C --> C1[hid_asus reload<br/>systemd service]
    D --> D1[Disable Intel PSR<br/>i915.enable_psr=0]
    E --> E1[Update Cirrus<br/>firmware]
    F --> F1[Install asusctl<br/>Configure TLP]
    
    B1 --> G[✅ Fixed]
    C1 --> G
    D1 --> G
    E1 --> H[⚠️ Partial]
    F1 --> G
    
    style G fill:#e8f5e8
    style H fill:#fff3e0
```

## Troubleshooting Flow

```mermaid
graph TD
    A[Installation Issues] --> B{Boot Problems?}
    B -->|Yes| C[Check GRUB Config]
    B -->|No| D{Hardware Issues?}
    
    C --> C1[Verify EFI Partition]
    C1 --> C2[Regenerate GRUB]
    C2 --> E[Test Boot]
    
    D -->|Yes| F[Apply Z13 Fixes]
    D -->|No| G{Performance Issues?}
    
    F --> F1[Wi-Fi Fix]
    F --> F2[Touchpad Fix]
    F --> F3[Display Fix]
    F1 --> E
    F2 --> E
    F3 --> E
    
    G -->|Yes| H[Check Power Profiles]
    G -->|No| I[Check Documentation]
    
    H --> H1[Configure TLP]
    H1 --> E
    
    I --> J[Community Support]
    
    E --> K{Fixed?}
    K -->|Yes| L[✅ Success]
    K -->|No| J
    
    style L fill:#e8f5e8
    style J fill:#fff3e0
```

## Performance Optimization Path

```mermaid
graph LR
    A[Performance Goals] --> B[Maximum Performance<br/>When Plugged In]
    A --> C[Optimal Battery Life]
    A --> D[Fast Boot Times]
    
    B --> B1[TLP Performance Mode]
    B --> B2[CPU Governor: Performance]
    B --> B3[54W+ TDP Limit]
    
    C --> C1[TLP Power-Save Mode]
    C --> C2[CPU Governor: Powersave]
    C --> C3[7W TDP Limit]
    
    D --> D1[systemd-boot]
    D --> D2[Minimal Services]
    D --> D3[SSD Optimizations]
    
    style B1 fill:#ffcdd2
    style B2 fill:#ffcdd2
    style B3 fill:#ffcdd2
    style C1 fill:#c8e6c9
    style C2 fill:#c8e6c9
    style C3 fill:#c8e6c9
    style D1 fill:#e1f5fe
    style D2 fill:#e1f5fe
    style D3 fill:#e1f5fe
```

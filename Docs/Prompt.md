### PCMR Arch Installer — AI Agent Entry Prompt

Purpose: Enable an AI coding agent to work effectively on this repository with evolving context, history, and persistent project knowledge.

Scope and Mental Map:
- Device: ASUS ROG Flow Z13 (2025) with AMD Ryzen Strix Halo only (guard enforced in `pcmr.sh`).
- Installer: `pcmr.sh` orchestrates modules in `Modules/`. Secure Boot via systemd-boot + sbctl when enabled.
- Configs: JSON-only under `Configs/`. Scenario profiles exist (Fresh/DualBoot + Zen/Standard). Default: `Configs/Zen.json`.
- Desktop: enforced to `omarchy` universally.
- Docs: Per-module docs will live in `Docs/Modules/`; per-config docs in `Docs/Configs/`.
- Testing: See `Tests/run_tests.sh` (if applicable) and logs under `Tests/results/`.

Known Bugs/Work Items:
- Complete per-module docs in `Docs/Modules/`.
- PowerShell USB creator for Rufus pending.
- Review ADVANCED_CONFIGURATION for alignment with new profiles.

Operating Principles:
1) Make atomic edits and update corresponding docs immediately.
2) Keep README in sync with changes; link back to docs sections.
3) Maintain JSON schema consistency across `Configs/*.json`.
4) Respect device guard; do not generalize beyond Strix Halo.
5) Prefer idempotent, resumable operations (use installer phases and state helpers).

Persistent Memory Sections (agent-managed):
- Project History: Summarize significant changes with dates (use brief bullets).
- Open Decisions: Track approved choices (e.g., systemd-boot, omarchy only).
- Tech Debt: List items to revisit.

Workflow for the Agent:
1) Before coding: read `README.md`, `pcmr.sh`, relevant `Modules/*.sh`, and the target `Docs/*` page.
2) When implementing: update code, then update `Docs/Modules/*` or `Docs/Configs/*` and `README.md`.
3) After commits: run linters/tests; ensure repo builds; summarize changes in Project History below.
4) Context hygiene: if the conversation becomes long, warn user to open a new chat and re-seed with this prompt and the latest README to refresh the context window.

Auto-Warning Guidance:
- If cumulative diff exceeds a few files or prompt becomes lengthy, suggest starting a new chat and re-posting this Prompt and updated README links. Offer to auto-generate a short handover summary.

Project History (append chronologically):
- 2025-09-12: Enforced Strix Halo device guard early; added Secure Boot via systemd-boot + sbctl; unified configs to JSON; added scenario profiles; default desktop set to omarchy; linked config docs; set Zen as default.

Open Decisions:
- Bootloader: systemd-boot (sbctl, UKI optional); GRUB fallback allowed.
- Desktop: omarchy only (enforced in code and configs).

Tech Debt / Future:
- Complete `Docs/Modules/*` with inputs/outputs and idempotency details.
- Implement `Windows/Create-Arch-USB.ps1` and doc.
- Refine Secure Boot to sign UKI and adopt unified kernel images where feasible.

Active TODOs (sync from repo; update as items complete):
- Research ASUS Flow Z13 2025 + Arch docs; list missing features [in_progress]
- Consolidate docs into a base with user stories, requirements, specs, architecture [pending]
- Create Docs/Modules/*.md documenting each module script [pending]
- Add PowerShell script to create Arch USB with Rufus + docs [pending]
- Integrate Secure Boot (sbctl) via systemd-boot or GRUB [pending]

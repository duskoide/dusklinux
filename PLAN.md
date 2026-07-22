# dusklinux — Plan & Roadmap

> A minimal Linux distribution built on **Alpine**, where the base behaves like a
> normal distro and **Nix + Home Manager** declaratively manages *only* the
> desktop (**niri** + **DankMaterialShell**) and shells/dotfiles.
> Distributed as a **custom live/installer ISO**.

---

## 1. Vision & Scope

**What dusklinux IS**
- A minimal Alpine base system: `apk`, `OpenRC`, musl, FHS layout — everything
  behaves exactly like a normal Linux distro.
- A declaratively-managed desktop layer on top, owned entirely by Nix + Home
  Manager: **niri** (compositor), **DMS / DankMaterialShell** (shell), and
  shells + dotfiles.
- Reproducible: the desktop layer lives in a flake; `home-manager switch`
  rebuilds it atomically with rollback.
- Shipped as a custom bootable ISO that installs the base + bootstraps the
  desktop in one go.

**What dusklinux is NOT**
- Not NixOS. Nix is a *user-space layer*, not the system. The OS itself is
  managed the traditional Alpine way (`apk`, `OpenRC` configs, `/etc`).
- Not built from source (no LFS-style toolchain). We assemble, we don't compile
  the world.
- Not a general-purpose package repo. We don't package things into Alpine; we
  pull the desktop stack from Nix.

**Scope boundary (the golden rule):**
> `apk`/`OpenRC` owns the *system*. Home Manager owns *only* `niri`, `dms`,
> `quickshell`, shells, and dotfiles. Nothing else crosses the line.

System-side services that support the desktop — `seatd` and `greetd`/tuigreet —
live on the Alpine/`OpenRC` side (configured under `/etc`), **not** in Home
Manager.

---

## 2. Architecture

```
┌──────────────────────────────────────────────────────────┐
│  Nix + Home Manager  (declarative desktop layer)         │
│    • niri            — scrollable-tiling Wayland comp.   │
│    • DMS             — DankMaterialShell (shell)         │
│    • quickshell      — DMS runtime (Qt6/QML)             │
│    • shells + dotfiles — zsh/fish, starship, git, etc.   │
│    → all from the Nix store: self-contained, glibc-bundled│
│      (so they run fine on a musl host), atomic rollback   │
├──────────────────────────────────────────────────────────┤
│  Alpine Linux  (the "normal linux" base)                 │
│    • kernel (linux-lts) • OpenRC init                    │
│    • apk package manager • coreutils, drivers, firmware  │
│    • base system behaves like any standard distro        │
│    • Nix is installed here as a normal user-space tool   │
├──────────────────────────────────────────────────────────┤
│  Hardware / VM                                           │
└──────────────────────────────────────────────────────────┘
```

### Why this split works (the key insight)
- `niri` is only in Alpine **`edge`/community**, and **DMS / quickshell aren't in
  Alpine repos at all**. Pulling them from Nix sidesteps both the packaging gap
  *and* the musl compatibility problem (Nix store binaries bundle their own
  libs), in a single move.
- The base stays 100% "normal Alpine" — no exotic init, no declarative OS, no
  lock-in. You can uninstall the Nix layer and still have a working system.

---

## 3. Design Decisions

| # | Decision | Choice | Rationale |
|---|----------|--------|-----------|
| 1 | Base distro | **Alpine** | Minimal, musl, apk, OpenRC. Matches the "minimal distro" vision. |
| 2 | Init system | **OpenRC** (Alpine default) | Not systemd. Affects which packages & how services are wired. |
| 3 | Desktop mgmt | **Nix + Home Manager (standalone)** | Declarative desktop + dotfiles with rollback; runs on top of normal distro. |
| 4 | Scope of HM | **Only niri, DMS, quickshell, shells, dotfiles** | Keeps base "normal"; clean ownership boundary. |
| 5 | niri source | Flake (`sodiboo/niri-flake` or `niri-wm/niri`) / nixpkgs | Fresh version + HM module; avoid tracking Alpine `edge`. |
| 6 | DMS source | Flake `AvengeMedia/DankMaterialShell` (has HM module) | First-class Nix support; pulls matching quickshell. |
| 7 | quickshell | Follow nixpkgs via DMS flake (pin `inputs.nixpkgs.follows`) | Qt6 app; mismatched system deps = crashes. |
| 8 | Nix install | Single-user, official installer script | Simplest on a non-NixOS host; no daemon. |
| 9 | Distribution | **Custom live/installer ISO via `mkimage` (aports)** | The "real distro" deliverable. |
| 10 | Install mode | Real `setup-disk` install to disk (not diskless) | Daily-driver, not a RAM-only live system. |
| 11 | Login shell | **zsh** — reuse existing `shell.nix` | User's working config (powerlevel10k + fzf-tab + vi-mode). |
| 12 | HM base config | Port existing `~/.config/home-manager/` | Already sets `targets.genericLinux` (non-NixOS ready). |
| 13 | Installer UX | **Interactive prompts** | Safer for real installs; confirms the target disk. |
| 14 | Display manager | **greetd + tuigreet** | Minimal, Wayland/niri-friendly, no systemd; system-side (OpenRC). |
| 15 | Target arch | **x86_64 only** (aarch64 later) | Fastest to build/test; add ARM later. |
| 16 | Dotfiles | Reuse `~/dotfiles` out-of-store symlinks | No rebuild to edit; installer clones the repo. |
| 17 | Browser | **Native via Nix** (not flatpak/Zen) | Self-contained glibc bundle runs on musl; avoids flatpak fragility. |
| 18 | Terminal | **kitty** (add to `home.packages`) | niri/DMS need a terminal; currently only the `TERMINAL` env var is set. |

---

## 4. Repository Layout

```
dusklinux/
├── README.md
├── PLAN.md                 # this document
├── LICENSE
├── flake.nix               # pins nixpkgs, home-manager, niri, dms
├── flake.lock
│
├── home/                   # ── Home Manager (desktop + dotfiles) ──
│   ├── home.nix            # ported from ~/.config/home-manager/home.nix
│   ├── shell.nix           # ported from ~/.config/home-manager/shell.nix (zsh)
│   ├── niri/
│   │   └── config.kdl      # niri compositor config (terminal = kitty)
│   └── dms/
│       └── ...             # DMS/quickshell config + theme
│
├── iso/                    # ── custom live/installer ISO ──
│   ├── mkimg.dusk.sh       # aports mkimage profile (based on mkimg.standard.sh)
│   ├── genapkovl-dusk.sh   # overlay builder: bakes /etc tweaks + bootstrap
│   └── overlay/            # static files added to the ISO
│       └── etc/
│           ├── greetd/config.toml   # tuigreet → niri-session
│           └── ...                  # other base /etc tweaks
│
└── scripts/
    ├── dusk-install.sh     # base setup (setup-alpine/setup-disk) + nix + HM
    └── bootstrap-nix.sh    # install Nix (single-user) on a fresh Alpine
```

---

## 5. Roadmap

Each phase is a numbered list of concrete steps — tick them off as you go.
Do the phases in order; each one de-risks the next. **Prove the stack by hand
before automating it.**

### Progress overview

Tick a phase when all of its steps are done.

- [ ] **Phase 0** — Preparation & Environment
- [ ] **Phase 1** — Prove the desktop by hand *(highest risk — do first)*
- [ ] **Phase 2** — Declarify into Home Manager
- [ ] **Phase 3** — Build the custom base ISO
- [ ] **Phase 4** — Wire the installer
- [ ] **Phase 5** — Hardening & daily-driver polish
- [ ] **Phase 6** — Distribution & docs

---

### Phase 0 — Preparation & Environment
**Goal:** A safe, repeatable workspace and the reference knowledge in hand.

1. [ ] Install a VM manager (QEMU + virt-manager) on your build host.
2. [ ] Create a throwaway VM (≥2 vCPU, ≥4 GB RAM, virtio-gpu, UEFI optional).
3. [ ] Download a current Alpine **`standard`** (or `virt`) ISO and attach it.
4. [ ] Read the Alpine `setup-alpine` / `setup-disk` docs.
5. [ ] Read the Alpine `mkimage` wiki (custom ISO build).
6. [ ] Read the Home Manager manual — the **standalone** (non-NixOS) install path.
7. [ ] Read the niri distro-integration notes + DMS NixOS/flake install docs.
8. [ ] Pin exact flake revisions: nixpkgs, home-manager, niri, dms, quickshell.

**Acceptance:** The VM boots a stock Alpine ISO to a root shell; the docs above
have been read and flake revisions are pinned.

---

### Phase 1 — Prove the desktop by hand (highest-risk phase)
**Goal:** niri + DMS launch from a TTY on a throwaway Alpine VM, installed via
Nix, *before* any automation.

1. [ ] Install the Alpine base into the VM disk (`setup-alpine` → `setup-disk`),
      reboot into it.
2. [ ] Create a non-root user; add it to `wheel`, `video`, `input`, `seat`.
3. [ ] Install base Wayland/GPU prereqs via apk: `seatd eudev mesa libinput`
      `pipewire wireplumber` + a font package (`font-noto` or similar).
4. [ ] Enable + start the OpenRC `seatd` service; confirm it's running.
5. [ ] Install Nix (single-user) via the official installer script.
6. [ ] Source the Nix profile; confirm `nix --version` works as your user.
7. [ ] Enable flakes (add `experimental-features = nix-command flakes`).
8. [ ] Write a scratch `flake.nix` with the inputs from §4 / the design table.
9. [ ] Add niri + DMS + quickshell via the flake (HM or plain `nix profile`).
10. [ ] Ensure quickshell's nixpkgs **follows** your nixpkgs (avoid crashes).
11. [ ] Write a minimal niri `config.kdl`; launch `niri-session` from a TTY.
12. [ ] Confirm niri renders; start DMS and confirm the shell appears.
13. [ ] Take a screenshot to prove the full stack works.

**Acceptance:** From a TTY login, niri starts and the DMS shell renders, with a
screenshot to prove it. This validates the entire novel part of the project.

**Risks to resolve here:** musl/Nix interop, seatd permissions, GPU drivers in
the VM (use virtio-gpu/virgl), quickshell↔nixpkgs version match, and OpenRC
(not systemd) wiring for starting the session.

---

### Phase 2 — Declarify into Home Manager
**Goal:** Everything from Phase 1 lives in the flake and is reproducible.

1. [ ] Port your existing `~/.config/home-manager/{home.nix,shell.nix}` into
      `home/` as the starting point (keep zsh, packages, git, and dotfiles
      symlinks as-is).
2. [ ] Add `niri`, `dms` (and quickshell) inputs to `flake.nix`, all following
      nixpkgs.
3. [ ] Add `kitty` to `home.packages`; confirm `TERMINAL=kitty` resolves.
4. [ ] Replace the Zen-flatpak `mimeApps` block with a native browser
      (Firefox / Zen build from nixpkgs) and set `BROWSER`.
5. [ ] Create `home/niri/config.kdl`; wire niri into HM (file or niri-flake HM
      module); set its terminal to kitty.
6. [ ] Wire DMS's Home Manager module; enable it; let it own quickshell.
7. [ ] Review `shell.nix` aliases: drop distro-specific ones
      (grub/zypper/fedora/suse) and fix the `homesw` flake path.
8. [ ] Verify quickshell follows nixpkgs (no crashes after rebuild).
9. [ ] Run `home-manager switch` from a clean state; confirm the desktop works.
10. [ ] Test rollback with `home-manager generations` / `--rollback`.
11. [ ] Document the system-side bits HM can't own (OpenRC: `seatd`, `greetd`)
      as small scripts outside Home Manager.

**Acceptance:** Wipe `~/.config`, run `home-manager switch`, and the desktop
works again; rollback via `home-manager generations` is confirmed.

---

### Phase 3 — Build the custom base ISO
**Goal:** A bootable dusklinux ISO built with `mkimage`.

1. [ ] Clone `aports`; read `scripts/mkimg.standard.sh` + `mkimg.base.sh`.
2. [ ] Write `iso/mkimg.dusk.sh`, starting from the `standard` profile.
3. [ ] Add base packages to the ISO: `seatd mesa eudev linux-lts`, firmware,
      `git curl sudo`, and a font package.
4. [ ] Write `iso/genapkovl-dusk.sh` to bake `/etc` tweaks into the overlay.
5. [ ] Add the bootstrap/installer script into the ISO overlay.
6. [ ] Build the ISO with `mkimage`.
7. [ ] Boot the resulting ISO in a fresh VM.

**Acceptance:** The custom ISO boots to a working live root shell with the
needed base packages already present.

---

### Phase 4 — Wire the installer
**Goal:** Fresh ISO → fully working dusklinux, semi-automated.

1. [ ] Write `scripts/dusk-install.sh` as the entry point.
2. [ ] Prompt for hostname, username, password, timezone (wrap `setup-alpine`).
3. [ ] Partition + format the target disk and run `setup-disk`.
4. [ ] Install + enable OpenRC services: `seatd`, `greetd`, networking, `acpid`.
5. [ ] Write `/etc/greetd/config.toml` (tuigreet → `niri-session` command).
6. [ ] Install Nix (single-user) via `scripts/bootstrap-nix.sh`.
7. [ ] Fetch the dusklinux flake (from git or the ISO) for the new user.
8. [ ] Clone the dotfiles repo to `~/dotfiles` (the symlink target).
9. [ ] Run `home-manager switch` to apply the desktop layer.
10. [ ] Enable greetd login so boot lands in niri + DMS.
11. [ ] Test end-to-end on a **clean VM**: boot ISO → installer → reboot →
      login → desktop appears.
12. [ ] Repeat the clean-VM install once more to confirm reproducibility.

**Acceptance:** A fully reproducible install from ISO to working desktop on a
clean VM, repeatable twice with the same result.

---

### Phase 5 — Hardening & daily-driver polish
**Goal:** Pleasant and safe to actually use.

1. [ ] Configure the bootloader (GRUB/syslinux), kernel params, initramfs.
2. [ ] Document + test GPU drivers for real hardware (Intel / AMD / NVIDIA).
3. [ ] Get audio working (pipewire + wireplumber) and verify output.
4. [ ] Get power/suspend and brightness working.
5. [ ] Get bluetooth working (if needed).
6. [ ] Set up networking (NetworkManager or `ifupdown`/`iwd`).
7. [ ] Configure sudo/doas policy for the user.
8. [ ] Set up automated backups of `/etc` + the flake (lbu or git).
9. [ ] (Optional) Add a `cachix`/binary cache to speed up Nix builds on install.

**Acceptance:** Installed on real hardware and survives a full day of normal use
(audio, wifi, suspend, updates) without manual fixes.

---

### Phase 6 — Distribution & docs
**Goal:** Someone else (or future-you) can reproduce it.

1. [ ] Finalize `README.md`: install instructions, architecture, philosophy.
2. [ ] Write reproducible ISO-build instructions.
3. [ ] Publish the ISO + the build instructions.
4. [ ] (Optional) Add CI to build the ISO on tag.
5. [ ] Version the flake and the ISO together (tag releases).

**Acceptance:** A clean checkout plus the README reproduces dusklinux from
scratch.

---

## 6. Risks & Mitigations

| Risk | Impact | Mitigation |
|------|--------|------------|
| musl/Nix interop issues | Desktop apps fail | Nix store is self-contained (glibc-bundled); validated in Phase 1 before investing further. |
| quickshell ↔ nixpkgs version mismatch | Shell crashes | Always `inputs.nixpkgs.follows = "nixpkgs"`; let DMS flake own the pin. |
| OpenRC vs systemd for DMS autostart | Autostart wiring differs | Use niri-session from TTY or an OpenRC/getty autologin + a small start script; don't rely on systemd user units. |
| seat management (seatd) perms | niri won't start | Add user to `seat`/`input`/`video` groups; enable OpenRC `seatd`; validate in Phase 1. |
| GPU in VM vs real HW | Can't test desktop | Use virtio-gpu/virgl in VM; document real-GPU paths in Phase 5. |
| niri only in Alpine edge | Base fragility | Irrelevant — niri comes from Nix, not apk. |
| ISO tooling learning curve (mkimage) | Phase 3 slips | Start from `mkimg.standard.sh`; change one thing at a time; test boot each change. |
| Scope creep (HM owning too much) | Base no longer "normal" | Enforce the §1 golden rule; keep system config in `apk`/`/etc`/OpenRC. |

---

## 7. Resolved Decisions

All open questions have been answered:

| Topic | Decision |
|-------|----------|
| Login shell | **zsh** — reuse the existing `shell.nix` (powerlevel10k + fzf-tab + vi-mode) |
| HM base config | Port the existing `~/.config/home-manager/{home.nix,shell.nix}` |
| Installer UX | **Interactive prompts** (hostname, user, password, timezone, disk) |
| Login / display manager | **greetd + tuigreet** (minimal, Wayland/niri-friendly, no systemd) |
| Target arch | **x86_64 only** first; aarch64 later |
| Install mode | **Real disk install** via `setup-disk` (not diskless) |
| Dotfiles | Reuse `~/dotfiles` out-of-store symlinks; installer clones the repo |
| Default browser | **Native via Nix** (self-contained, works on musl); not flatpak/Zen |
| Terminal | **kitty** (add to `home.packages`; only `TERMINAL` env is set today) |
| `stateVersion` | Keep **`24.11`** to avoid option-default churn |

### Remaining minor questions

- **Branding:** bootsplash, default hostname, `/etc/os-release` identity.
- **Exact native browser:** Firefox vs. a Zen build from nixpkgs.
- **Alias cleanup:** trim distro-specific zsh aliases (grub/zypper/fedora/suse)
  and update the `homesw` flake path for dusklinux.

---

## 8. References

- niri: https://github.com/niri-wm/niri · flake: `github:niri-wm/niri` ·
  community flake: https://github.com/sodiboo/niri-flake
- DankMaterialShell (DMS): https://github.com/AvengeMedia/DankMaterialShell ·
  docs: https://danklinux.com/docs/dankmaterialshell/nixos-flake
- quickshell: https://quickshell.org · flake: `github:quickshell-mirror/quickshell`
- Home Manager manual (standalone): https://home-manager.dev/manual/
- Nix on Alpine: https://heywoodlh.io/install-nix-alpine-linux/
- Alpine custom ISO (mkimage): https://wiki.alpinelinux.org/wiki/How_to_make_a_custom_ISO_image_with_mkimage
- aports mkimg scripts: https://github.com/alpinelinux/aports/tree/master/scripts
- niri distro integration notes:
  https://github.com/niri-wm/niri/blob/main/docs/wiki/Integrating-niri.md

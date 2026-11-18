# Nimble Arch Visual Interface (Navi)

Navi is my build of dwm, inspired by Luke Smith's LARBS. It is a keyboard-driven desktop built on suckless tools designed to run on Arch Linux-based systems.

Website: [navi-desktop.org](https://navi-desktop.org)

## What is Navi?

Navi is for people who already use tiling window managers and for people who are new to them. Everything comes pre-configured, so you don't have to spend hours setting up a new system. Because the setup is in plain files that you can read, Navi makes it easy to learn how a desktop like this works, and how to modify it.

## Installation

As your normal user, run:

```
curl -LO https://navi-desktop.org/navi.sh
sh navi.sh
```

This installs everything.

## After installation

- **Super+F1** opens the keybinds guide.
- Neomutt is installed but not set up. When you want it: `mw -a you@example.com`
- **Super+u** for updating your system.

## Customization

- **Programs:** add or remove names in `packages.txt`. Lines starting with `#` are ignored.
- **dwm, st, dwmblocks, etc:** edit `config.h` in `~/.local/src/`
- **Everything else:** the configs are in `~/.config`, and the scripts in `~/.local/bin`. **Super+F2** opens the main ones.

# xiv-flake

`xiv-flake` is a Nix flake that provides both [NixOS](https://github.com/NixOS) and [home-manager](https://github.com/nix-community/home-manager) options to help you manage [XIVLauncher](https://github.com/goatcorp/FFXIVQuickLauncher) declaratively.

It also contains additional options that are commonly associated with the game, such as providing reshade support.

`xiv-flake` does NOT manage your Dalamud plugins. For that, you will want to look at (nothing yet, but i'll eventually work on `dalamud-flake` ig).

## Usage

1. Add to your flake inputs.

```nix
xiv-flake = {
  url = "github:NekoDrone/xiv-flake";
  inputs.nixpkgs.follows = "nixpkgs";
};
```

2. Put it into your config.

```nix
# home.nix
{ inputs, ... }:

imports = [ inputs.xiv-flake.homeManagerModules.default ];

# for full options, please see docs/options.md (automatically generated).
programs.xivlauncher = {
  enable = true;

  settings = {
    game.path = "/path/to/game/binary"; # default set by xivlauncher is ~/.xlcore/ffxiv
  };
};
```

## Configuring XIVLauncher

Most of XIVLauncher's settings are contained within the attrset `programs.xivlauncher.settings`. Please see `docs/options.md` for the full list.

Otherwise, a guide to configuring XIVLauncher's settings declaratively is provided at `docs/configuring-xl.md`.

## ReShade Support

The option to enable ReShade support for your XIV installation is `programs.xivlauncher.game.reshade.enable`. Other options are similarly provided.

However, it is not as simple as setting `enable` to true to ensure proper ReShade support for your game installation. For more information, please see `docs/enabling-reshade.md`.

## Dalamud

Dalamud is enabled by default in upstream XIVLauncher. We follow suit. If you would like to disable Dalamud, please set `programs.xivlauncher.settings.dalamud.enable` to `false`.

## Contributing

Feel free to open an issue. PRs welcome.

## Acknowledgements

This flake would not be possible without the following people.

- The XIVLauncher and Dalamud team for making XIV less painful to launch.
- The XL.Core team for making XIV less painful to use on Linux.
- Abeehiltz, for helping me figure out how to properly set up ReShade and for providing examples when asked.

Additionally, the following repositories helped in making sure this flake was possible and sane.

- [liamsmith86/ffxiv-linux-reshade](https://github.com/liamsmith86/ffxiv-linux-reshade/)
- [kevinlekiller/reshade-steam-proton](https://github.com/kevinlekiller/reshade-steam-proton)

And of course, to Square Enix, CBU3, and Naoki Yoshida for making Final Fantasy XIV, the best MMO ever made.

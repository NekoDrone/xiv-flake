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
    game.path = "/path/to/game/binary"; # default set by xivlauncher is /home/<you>/.xlcore/ffxiv
  };
};
```

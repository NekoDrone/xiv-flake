# Enabling ReShade

This document covers both the background as well as the decisions made in order to easily enable ReShade support on NixOS systems with XIV.

**If you don't care, and you just want instructions, skip to the section titled "d3dcompiler_47.dll".**

## Background

"ReShade is a generic post-processing injector for games and video software developed by crosire.". This is fine for games running on Windows, as it means ReShade has access to standard Windows libraries and frameworks to use. In particular, Direct3D and the ability to run .exes.

Windows also doesn't need you to specify hashes in order to reproducibly build a system config.

We are thus presented with two problems. A lack of ReShade on the system, as well as a lack of Direct3D libraries to actually let ReShade work.

## A Stable ReShade

Getting ReShade on the system is fairly easy... if you want to do it imperatively.

The only 'official' source of ReShade is found at their [official site](https://reshade.me). And, it is neither version tagged, nor stable. The only available download URL also only provides a pre-built .dll inside of a .exe.

Earlier attempts at pulling in ReShade support for XIV on Linux involved grabbing said .exe, and unzipping it to pull the relevant `ReShade64.dll` into the game's Wine prefix.

This obviously does not fly with Nix, and so now [stable-reshade](https://github.com/NekoDrone/stable-reshade) exists to provide version-pinnable .dlls for ReShade.

## Shader Woes

That solves the problem of getting the ReShade library onto machines. Direct3D on the other hand presents another problem.

The vast majority of shader effects available to ReShade and its presets compile their D3D11 effects at runtime through D3DCompile.

The good news is that Wine provides this and is pretty good!

The bad news is that it doesn't have feature parity with Microsoft's. As a result, the majority of shader effects fail to load if you attempt to use Wine's own D3D compiler.

So, we look to Microsoft's official compiler to ensure that we can run the desired ReShade effects within the game.

The exact .dll that we need is `d3dcompiler_47.dll`. This is a proprietary Microsoft Direct3D library that is freely distributed on their web platform.

The bad news here is that we as a project cannot redistribute this library in any way without facing legal repercussions.

The good news is that we can tell you how to get it yourself, or have your own machine fetch it straight from Microsoft, so that it's available in the system when you're attempting to enable ReShade support.

## `d3dcompiler_47.dll`

Before ReShade can use Microsoft's compiler, `d3dcompiler_47.dll` needs to be in your Nix store, and the module needs to know about it. There are a couple of ways to go about that, so it has its own doc. Please see [Obtaining `d3dcompiler_47.dll`](./obtaining-d3dcompiler.md).

## Checking It Works

At this point, it would be wise to rebuild your system config and launch XIV to ensure that ReShade loads in properly.

Pressing the 'Home' key while in game will tell you if ReShade loads correctly.

## Installing Shader Effects

`reshade-shaders` (specifically the [EffectPackages.ini](https://github.com/crosire/reshade-shaders/blob/list/EffectPackages.ini)) is how ReShade on Windows actually installs all the commonly used shader effects like SweetFX. This list contains the source repositories that ReShade will download from in order to extract their shader and texture files.

Nix requires that you specify the hashes when installing a shader effect collection. An example for the "slim" `reshade-shaders` is given below.

```nix
# home/xivlauncher.nix
{ inputs, pkgs, ... }:
{

  imports = [ inputs.xiv-flake.homeManagerModules.default ];
  programs.xivlauncher = {
    enable = true;
    game = {
      reshade = {
        enable = true;
        shaders = [
          {
            src = pkgs.fetchFromGitHub {
              owner = "crosire";
              repo = "reshade-shaders";
              rev = "fd0022170615ce0d8162d219bff07232fa6dd84f";
              hash = "sha256-etLUys7rIxZzEdvT6Kmj593+G/UaJWpHdSSnfMZWZTg=";
            };
          }
        ];
      };
    };
  };
}
```

As usual for Nix users, if you are unsure of what the hash will be ahead of time, `pkgs.lib.fakeHash` will provide you with a placeholder you can then replace when the build fails (see the logs for the expected hash then use that!).

## Preset Management

There are two ways to source your ReShade presets.

1. Specify them inline.
2. Point to a file.

Both go in `programs.xivlauncher.game.reshade.presets`. Examples are provided below.

```nix
# home/xivlauncher.nix
{ inputs, pkgs, ... }:
{
  imports = [ inputs.xiv-flake.homeManagerModules.default ];
  programs.xivlauncher = {
    enable = true;
    game = {
      reshade = {
        enable = true;
        presets = {
          "Minimal" = ''
            Techniques=SMAA@SMAA.fx
            [SMAA.fx]
            EdgeDetectionThreshold=0.100000
          '';
          "Gameplay" = ./reshade/Gameplay.ini;
        };
      };
    };
  };
}
```

# Example Configuration

A minimal but usable configuration that also enables ReShade support is below. This is sourced directly from my (NekoDrone) personal nix flake [here](https://github.com/NekoDrone/wellspring).

```nix
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

        d3dcompiler = {
          enable = true;
          hash = "sha256-RDK70aOQh08/ClA9RcxI00arw6jAITwon0thW/DuhPM=";
        };
      };
    };
  };
}
```

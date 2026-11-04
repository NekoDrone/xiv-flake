{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.programs.xivlauncher.game.reshade;

  reshade = pkgs.callPackage ../../../pkgs/reshade.nix { };

  iniSeed = pkgs.writeText "ReShade.ini" ''
    [GENERAL]
    EffectSearchPaths=.\reshade-shaders\Shaders\**
    TextureSearchPaths=.\reshade-shaders\Textures\**
  '';
in
{
  imports = [
    ./shaders.nix
    ./presets.nix
    ./d3dcompiler.nix
  ];

  options.programs.xivlauncher.game.reshade = {
    enable = lib.mkEnableOption "ReShade for FFXIV";

    proxyDll = lib.mkOption {
      type = lib.types.enum [
        "dxgi"
        "d3d11"
      ];
      default = "dxgi";
      description = "Name ReShade is loaded under in the game directory.";
    };

    gamePath = lib.mkOption {
      type = lib.types.str;
      default = "${config.home.homeDirectory}/.xlcore/ffxiv/game";
      defaultText = lib.literalExpression ''"''${config.home.homeDirectory}/.xlcore/ffxiv/game"'';
      description = "Directory containing ffxiv_dx11.exe.";
    };
  };

  config = lib.mkIf (config.programs.xivlauncher.enable && cfg.enable) {
    home.activation.xivlauncherReshade = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      game=${lib.escapeShellArg cfg.gamePath}
      dll="$game/${cfg.proxyDll}.dll"

      if [ -d "$game" ]; then
        if [ -e "$dll" ] && [ ! -L "$dll" ]; then
          echo "reshade: $dll is a real file (another mod?), leaving it alone" >&2
        else
          run ln -sfn ${reshade}/ReShade64.dll "$dll"
        fi

        if [ ! -e "$game/ReShade.ini" ]; then
          run install -m644 ${iniSeed} "$game/ReShade.ini"
        fi
      else
        echo "reshade: $game not found, skipping (install the game first)" >&2
      fi
    '';
  };
}

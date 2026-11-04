self:
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.programs.xivlauncher;
  rs = cfg.game.reshade;

  reshade = pkgs.callPackage ../pkgs/reshade.nix { };

  shaderTree = pkgs.runCommand "reshade-shaders" { } ''
    mkdir -p $out/Shaders $out/Textures
    for p in ${lib.escapeShellArgs rs.shaders}; do
      if [ -d "$p/Shaders" ]; then
        cp -rsn "$p"/Shaders/. $out/Shaders/
      fi
      if [ -d "$p/Textures" ]; then
        cp -rsn "$p"/Textures/. $out/Textures/
      fi
    done
  '';

  iniSeed = pkgs.writeText "ReShade.ini" ''
    [GENERAL]
    EffectSearchPaths=.\reshade-shaders\Shaders\**
    TextureSearchPaths=.\reshade-shaders\Textures\**
  '';
in
{
  options.programs.xivlauncher = {
    enable = lib.mkEnableOption "XIVLauncher";
    package = lib.mkPackageOption pkgs "xivlauncher" { };

    game.reshade = {
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
        description = "Directory containing ffxiv_dx11.exe.";
      };

      shaders = lib.mkOption {
        type = lib.types.listOf lib.types.package;
        default = [ ];
        description = "Packages with Shaders/ and/or Textures/ at their root.";
      };
    };
  };

  config = lib.mkIf cfg.enable (
    lib.mkMerge [
      {
        home.packages = [ cfg.package ];
      }

      (lib.mkIf rs.enable {
        home.activation.xivlauncherReshade = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
          game=${lib.escapeShellArg rs.gamePath}
          dll="$game/${rs.proxyDll}.dll"

          if [ -d "$game" ]; then
            if [ -e "$dll" ] && [ ! -L "$dll" ]; then
              echo "reshade: $dll is a real file (another mod?), leaving it alone" >&2
            else
              run ln -sfn ${reshade}/ReShade64.dll "$dll"
            fi

            run ln -sfn ${shaderTree} "$game/reshade-shaders"

            if [ ! -e "$game/ReShade.ini" ]; then
              run install -m644 ${iniSeed} "$game/ReShade.ini"
            fi
          else
            echo "reshade: $game not found, skipping (install the game first)" >&2
          fi
        '';
      })
    ]
  );
}

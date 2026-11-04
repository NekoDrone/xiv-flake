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
  dc = rs.d3dcompiler;

  reshade = pkgs.callPackage ../pkgs/reshade.nix { };
  d3dcompiler = pkgs.callPackage ../pkgs/d3d.nix { hash = dc.hash; };

  shaderTree = pkgs.runCommand "reshade-shaders" { } ''
    mkdir -p $out/Shaders $out/Textures
    ${lib.concatMapStrings (
      s:
      let
        shaders = lib.escapeShellArg "${s.src}/${s.shaderDir}";
        textures = lib.escapeShellArg "${s.src}/${s.textureDir}";
        dir = lib.escapeShellArg s.installDir;
      in
      ''
        if [ -d ${shaders} ]; then
          mkdir -p "$out/Shaders/"${dir}
          cp -rsn ${shaders}/. "$out/Shaders/"${dir}/
        fi
        if [ -d ${textures} ]; then
          mkdir -p "$out/Textures/"${dir}
          cp -rsn ${textures}/. "$out/Textures/"${dir}/
        fi
      ''
    ) rs.shaders}
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
        type = lib.types.listOf (
          lib.types.submodule {
            options = {
              src = lib.mkOption { type = lib.types.package; };
              installDir = lib.mkOption {
                type = lib.types.str;
                default = "";
                description = "Subfolder under Shaders/ and Textures/ (the ini's InstallPath).";
              };
              shaderDir = lib.mkOption {
                type = lib.types.str;
                default = "Shaders";
              };
              textureDir = lib.mkOption {
                type = lib.types.str;
                default = "Textures";
              };
            };
          }
        );
        default = [ ];
      };

      # require user to go grab it on their own so we're not redistributing anything
      # realistically, the user should probably setup some sort of install script
      # to ensure the right d3dcompiler is on their system
      # for us, we're just checking the file and requiring it to proceed.
      d3dcompiler = {
        enable = lib.mkEnableOption "a native d3dcompiler_47.dll in the Wine prefix";
        hash = lib.mkOption {
          type = lib.types.nullOr lib.types.str;
          default = null;
          example = "sha256-AAAA...";
          description = "Hash of your d3dcompiler_47.dll (from `nix hash file`).";
        };
        prefixPath = lib.mkOption {
          type = lib.types.str;
          default = "${config.home.homeDirectory}/.xlcore/wineprefix";
          description = "XIVLauncher's Wine prefix.";
        };
      };
    };
  };

  config = lib.mkIf cfg.enable (
    lib.mkMerge [
      {
        home.packages = [ cfg.package ];
      }

      (lib.mkIf rs.enable {
        assertions = [
          {
            assertion = !dc.enable || dc.hash != null;
            message = "programs.xivlauncher.game.reshade.d3dcompiler.hash must be set when d3dcompiler is enabled.";
          }
        ];

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

        home.activation.xivlauncherD3dcompiler = lib.mkIf dc.enable (
          lib.hm.dag.entryAfter [ "writeBoundary" ] ''
            sys32=${lib.escapeShellArg "${dc.prefixPath}/drive_c/windows/system32"}
            target="$sys32/d3dcompiler_47.dll"

            if [ -d "$sys32" ]; then
              if ! ${pkgs.diffutils}/bin/cmp -s ${d3dcompiler} "$target"; then
                if [ -e "$target" ] && [ ! -e "$target.orig" ]; then
                  run cp "$target" "$target.orig"
                fi
                run install -m644 ${d3dcompiler} "$target"
              fi
            else
              echo "reshade: $sys32 not found, skipping d3dcompiler (launch XIVLauncher once first)" >&2
            fi
          ''
        );
      })
    ]
  );
}

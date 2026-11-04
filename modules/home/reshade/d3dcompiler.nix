{
  config,
  lib,
  pkgs,
  ...
}:
let
  rs = config.programs.xivlauncher.game.reshade;
  cfg = rs.d3dcompiler;

  d3dcompiler = pkgs.callPackage ../../../pkgs/d3d.nix { hash = cfg.hash; };
in
{
  # require user to go grab it on their own so we're not redistributing anything
  # realistically, the user should probably setup some sort of install script
  # to ensure the right d3dcompiler is on their system
  # for us, we're just checking the file and requiring it to proceed.
  options.programs.xivlauncher.game.reshade.d3dcompiler = {
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
      defaultText = lib.literalExpression ''"''${config.home.homeDirectory}/.xlcore/wineprefix"'';
      description = "XIVLauncher's Wine prefix.";
    };
  };

  config = lib.mkIf (config.programs.xivlauncher.enable && rs.enable && cfg.enable) {
    assertions = [
      {
        assertion = cfg.hash != null;
        message = "programs.xivlauncher.game.reshade.d3dcompiler.hash must be set when d3dcompiler is enabled.";
      }
    ];

    home.activation.xivlauncherD3dcompiler = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      sys32=${lib.escapeShellArg "${cfg.prefixPath}/drive_c/windows/system32"}
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
    '';
  };
}

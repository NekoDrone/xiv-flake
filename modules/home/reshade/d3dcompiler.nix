{
  config,
  lib,
  pkgs,
  ...
}:
let
  rs = config.programs.xivlauncher.game.reshade;
  cfg = rs.d3dcompiler;

  d3dcompiler =
    if cfg.package != null then
      cfg.package
    else
      pkgs.callPackage ../../../pkgs/d3d.nix { inherit (cfg) hash; };
in
{
  # users who'd rather have nix fetch it from microsoft can set `package`
  # to pkgs/d3d-url.nix (exposed as `xivlauncher-d3dcompiler-url` in the overlay).
  #
  # by default, require user to go grab it on their own so we're not redistributing anything
  # realistically, the user should probably setup some sort of install script
  # to ensure the right d3dcompiler is on their system
  # for us, we're just checking the file and requiring it to proceed.
  options.programs.xivlauncher.game.reshade.d3dcompiler = {
    enable = lib.mkEnableOption "a native d3dcompiler_47.dll in the Wine prefix";
    hash = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      example = "sha256-AAAA...";
      description = ''
        Hash of the d3dcompiler_47.dll you added to the Nix store yourself
        (from `nix hash file`). Ignored when {option}`package` is set.
      '';
    };
    package = lib.mkOption {
      type = lib.types.nullOr lib.types.package;
      default = null;
      example = lib.literalExpression "pkgs.xivlauncher-d3dcompiler-url";
      description = ''
        A derivation that outputs a d3dcompiler_47.dll file.

        Whn `null`, uses a locally sourced (`requireFile`) .dll added to the
        Nix store imperatively.

        If you want to have Nix fetch it for you from Microsoft (which is
        potentially unstable), set it to `pkgs.xivlauncher-d3dcompiler-url`
        instead. Setting this option requires unfree packages to be installed
        on your nixpkgs configuration.
      '';
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
        assertion = cfg.hash != null || cfg.package != null;
        message = "programs.xivlauncher.game.reshade.d3dcompiler: set either `hash` (a DLL you added to the store) or `package` (e.g. pkgs.xivlauncher-d3dcompiler-url) when d3dcompiler is enabled.";
      }
    ];

    warnings =
      lib.optional (cfg.package != null && cfg.hash != null)
        "programs.xivlauncher.game.reshade.d3dcompiler: both `package` and `hash` are set; `package` is ignored.";

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

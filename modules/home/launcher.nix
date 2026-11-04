{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.programs.xivlauncher;
in
{
  options.programs.xivlauncher = {
    enable = lib.mkEnableOption "XIVLauncher";
    package = lib.mkPackageOption pkgs "xivlauncher" { };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ cfg.package ];
  };
}

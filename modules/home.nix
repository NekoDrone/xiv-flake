# modules/home.nix
self:
{
  config,
  lib,
  pkgs,
  osConfig ? null,
  ...
}:
let
  cfg = config.programs.xivlauncher;
  # sysGamemode = lib.attrByPath [ "programs" "gamemode" "enable" ] false osConfig;
in
{
  options.programs.xivlauncher = {
    enable = lib.mkEnableOption "XIVLauncher";
    package = lib.mkPackageOption pkgs "xivlauncher" { };
    reshade.enable = lib.mkEnableOption "ReShade for FFXIV";
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ cfg.package ];
    # do reshade
  };
}

self:
{
  config,
  lib,
  options,
  pkgs,
  ...
}:
let
  cfg = config.programs.xivlauncher;
in
{
  options.programs.xivlauncher = {
    enable = lib.mkEnableOption "XIVLauncher system prerequisites";
    gamemode.enable = lib.mkEnableOption "GameMode";
  };

  config = lib.mkIf cfg.enable (
    lib.mkMerge [
      { hardware.graphics.enable = true; }
      (lib.mkIf cfg.gamemode.enable { programs.gamemode.enable = true; })
      (lib.optionalAttrs (options ? home-manager) {
        home-manager.sharedModules = [ self.homeManagerModules.default ];
      })
    ]
  );
}

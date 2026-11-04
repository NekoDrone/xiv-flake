{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.programs.xivlauncher.game.reshade;

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
    ) cfg.shaders}
  '';
in
{
  options.programs.xivlauncher.game.reshade.shaders = lib.mkOption {
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

  config = lib.mkIf (config.programs.xivlauncher.enable && cfg.enable) {
    home.activation.xivlauncherReshadeShaders = lib.hm.dag.entryAfter [ "xivlauncherReshade" ] ''
      game=${lib.escapeShellArg cfg.gamePath}
      if [ -d "$game" ]; then
        run ln -sfn ${shaderTree} "$game/reshade-shaders"
      fi
    '';
  };
}

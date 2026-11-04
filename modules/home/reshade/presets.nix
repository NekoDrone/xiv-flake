{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.programs.xivlauncher.game.reshade;

  isStorePathString = v: lib.isString v && lib.hasPrefix "${builtins.storeDir}/" v;

  isFileRef = v: builtins.isPath v || lib.isDerivation v || isStorePathString v;

  isBarePathString =
    v: lib.isString v && !isStorePathString v && builtins.match "(~|\\.{1,2})?/[^\n]*" v != null;

  presetType = lib.types.either (lib.types.addCheck lib.types.path isFileRef) lib.types.lines;

  presetFile = name: v: if isFileRef v then v else pkgs.writeText "${name}.ini" v;

  presetTree = pkgs.linkFarm "reshade-presets" (
    lib.mapAttrsToList (name: v: {
      name = "${lib.removeSuffix ".ini" name}.ini";
      path = presetFile name v;
    }) cfg.presets
  );

  install =
    if cfg.presetMode == "link" then
      ''
        if [ -e "$presets" ] && [ ! -L "$presets" ]; then
          echo "reshade: $presets is a real directory, not replacing it" >&2
        else
          run ln -sfn ${presetTree} "$presets"
        fi
      ''
    else
      ''
        if [ -L "$presets" ]; then run rm "$presets"; fi
        run mkdir -p "$presets"
        for f in ${presetTree}/*; do
          [ -e "$f" ] || continue
          [ -e "$presets/$(basename "$f")" ] || run install -m644 "$f" "$presets/"
        done
      '';
in
{
  options.programs.xivlauncher.game.reshade = {
    presets = lib.mkOption {
      type = lib.types.attrsOf presetType;
      default = { };
      description = "ReShade presets by name: a file (path literal, derivation, or file inside a store path) or inline ini text.";
    };

    presetMode = lib.mkOption {
      type = lib.types.enum [
        "link"
        "copy"
      ];
      default = "link";
      description = ''
        link: presets are read-only and fully managed (in-game changes won't save).
        copy: presets are seeded once and stay editable in-game.
      '';
    };
  };

  config = lib.mkIf (config.programs.xivlauncher.enable && cfg.enable) {
    assertions = lib.concatLists (
      lib.mapAttrsToList (name: v: [
        {
          assertion = builtins.match "[A-Za-z0-9._ -]+" name != null;
          message = "reshade preset name '${name}' must be a plain file name";
        }
        {
          assertion = !isBarePathString v;
          message = ''
            reshade preset '${name}' is the string "${v}", which looks like a path but isn't one Nix can read.
            Use a path literal without quotes (./foo.ini), a fetcher (pkgs.fetchurl), or a file inside a
            fetched source ("''${src}/foo.ini").
          '';
        }
      ]) cfg.presets
    );

    home.activation.xivlauncherReshadePresets = lib.mkIf (cfg.presets != { }) (
      lib.hm.dag.entryAfter [ "xivlauncherReshade" ] ''
        game=${lib.escapeShellArg cfg.gamePath}
        presets="$game/reshade-presets"
        if [ -d "$game" ]; then
        ${install}
        fi
      ''
    );
  };
}

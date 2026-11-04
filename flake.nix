{

  description = "Flake to provide module options (both home-manager and nixos) for XIVLauncher";

  outputs =
    { self, nixpkgs }:
    let
      systems = [ "x86_64-linux" ];
      forAll = f: nixpkgs.lib.genAttrs systems (s: f nixpkgs.legacyPackages.${s});
    in
    {
      packages = forAll (pkgs: {
        reshade = pkgs.callPackage ./pkgs/reshade.nix { };
      });

      overlays.default = final: _: {
        xivlauncher-reshade = final.callPackage ./pkgs/reshade.nix { };
      };

      homeManagerModules.default = import ./modules/home self;
      nixosModules.default = import ./modules/nixos.nix self;
    };

}

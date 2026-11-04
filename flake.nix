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
        reshade-setup = pkgs.callPackage ./pkgs/reshade-setup.nix { };
      });

      overlays.default = final: _: {
        xivlauncher-reshade-setup = final.callPackage ./pkgs/reshade-setup.nix { };
      };

      homeManagerModules.default = import ./modules/home.nix self;
      nixosModules.default = import ./modules/nixos.nix self;
    };

}

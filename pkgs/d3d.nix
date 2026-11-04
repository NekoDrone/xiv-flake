{ requireFile, hash }:
requireFile {
  name = "d3dcompiler_47.dll";
  inherit hash;
  message = ''
    d3dcompiler_47.dll (64-bit) is not in the Nix store.

    Get it with winetricks in a throwaway prefix:
      export WINEPREFIX=$(mktemp -d)
      winetricks -q d3dcompiler_47
      cp "$WINEPREFIX/drive_c/windows/system32/d3dcompiler_47.dll" .

    Then add it:
      nix-store --add-fixed sha256 d3dcompiler_47.dll
  '';
}

# we don't actually ship a d3dcompiler_47.dll because
# it is a proprietary microsoft binary.
# instead, we imperatively require the binary to be
# present in the nix store.
#
# this way we at least get some amount of consistency
# when it comes to using this flake.
#
# the reason we have to perform this in the first place
# is because the d3dcompiler dll provided to us by
# vkd3d still does not have feature parity with
# the versions available to windows users.
#
# as such, we have to find some way to provide it to reshade.
# this is the least painful way for downstream users.

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

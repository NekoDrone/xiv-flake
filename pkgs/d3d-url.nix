# an opt-in alternative to ./d3d.nix.
#
# instead of requiring the user to put d3dcompiler_47.dll into
# the nix store themselves, this fetches the windows sdk cab that
# contains it straight from microsoft and extracts the 64-bit dll.
# this is technically fine because we still aren't redistributing
# the library directly, and instead asking the user's machine to
# obtain it for them.
#
# this can get sketchy, which is why we also allow for users to
# really do it manually (see pkgs/d3d.nix). in fact, that is
# the default option provided by this flake.
#
# the catch is that this is pinned to a microsoft download url,
# and microsoft has moved this url before. when it moves again,
# override `url` (and `member`/`hash` if the cab changed), e.g.
#
#   pkgs.xivlauncher-d3dcompiler-url.override {
#     url = "https://download.microsoft.com/.../<whatever>.cab";
#     hash = "sha256-...";
#   }
#
# `hash` is the hash of the extracted dll, not of the cab, so it
# is the same hash `nix hash file d3dcompiler_47.dll` would give you.
# because the name and hash match ./d3d.nix, both produce the same
# store path for the same dll.
#
# defaults are taken from the windows sdk 10.0.28000.2705 cab, see
# https://github.com/Winetricks/winetricks/issues/2522

{
  lib,
  fetchurl,
  cabextract,
  url ? "https://download.microsoft.com/download/38ab8f6d-3676-4860-ae84-3361308b9d7f/KIT_BUNDLE_WINDOWSSDK_MEDIACREATION/Installers/61d57a7a82309cd161a854a6f4619e52.cab",
  # name of the x64 d3dcompiler_47.dll inside the cab
  member ? "fil3585cb2ea5db13cc0838f8d06b5c9679",
  hash ? "sha256-PlbBoIZ6oEy8qUizZk/KxdUSdYZc0ESkWj/WzmNu6RQ=",
}:
fetchurl {
  name = "d3dcompiler_47.dll";
  inherit url hash;

  downloadToTemp = true;
  nativeBuildInputs = [ cabextract ];
  postFetch = ''
    cabextract -q -L -d "$TMPDIR/cab" -F ${lib.escapeShellArg member} "$downloadedFile"
    install -m644 "$TMPDIR/cab/"${lib.escapeShellArg member} "$out"
  '';

  meta = {
    description = "Microsoft's d3dcompiler_47.dll (x64), fetched from the Windows SDK";
    homepage = "https://github.com/Winetricks/winetricks/issues/2522";
    license = lib.licenses.unfree;
    platforms = lib.platforms.all;
  };
}

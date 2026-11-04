{
  lib,
  stdenvNoCC,
  fetchurl,
}:
stdenvNoCC.mkDerivation rec {
  pname = "reshade-addon";
  version = "6.8.0";
  src = fetchurl {
    url = "https://github.com/NekoDrone/stable-reshade/releases/download/v6.8.0/ReShade64.dll";
    hash = "sha256-QvuE+gqiJEUOAZ555ft1et4AvVtVncZ3QK1mfZUgnrg=";
  };
  dontUnpack = true;
  installPhase = ''
    install -Dm644 $src $out/ReShade64.dll
  '';
  meta.license = lib.licenses.bsd3;
}

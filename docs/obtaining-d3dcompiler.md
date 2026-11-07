# Obtaining `d3dcompiler_47.dll`

This is a companion to [Enabling ReShade](./enabling-reshade.md), which covers why this library is needed in the first place.

The first step to enabling ReShade support on the system is getting this library into the Nix store. There are two ways to go about it.

1. **Let Nix fetch it.** Nix downloads the Windows SDK cab from Microsoft and pulls the .dll out of it for you. Convenient, but it is pinned to a Microsoft download URL, and Microsoft has moved that URL before, and so it's potentially unstable and certainly not wholly reproducible.
2. **Bring your own.** You download the .dll yourself and add it to the Nix store. More legwork, but your config only depends on the hash, not on where the file came from.

Both end up with the same file at the same store path, so you can switch between them freely.

Either way, the .dll is a proprietary Microsoft binary, and nixpkgs treats it as unfree. You'll need to allow it in your nixpkgs config, either with `allowUnfree = true` or, if you'd rather be specific, like so.

```nix
{ lib, ... }:
{
  nixpkgs.config.allowUnfreePredicate =
    pkg: builtins.elem (lib.getName pkg) [ "d3dcompiler_47.dll" ];
}
```

If you use home-manager as a NixOS module with `home-manager.useGlobalPkgs = true`, `nixpkgs.*` settings in your home config do nothing. Put them in your NixOS config instead.

## Using `winetricks`

Earlier versions of the docs told you to grab the .dll with `winetricks d3dcompiler_47`. **Don't.** That verb currently installs the 2013 build (6.3.9600) from the Windows 8.1 SDK, which fails to compile a lot of modern shaders with `error X4014: cannot have divergent gradient operations inside flow control`. See [Winetricks/winetricks#2522](https://github.com/Winetricks/winetricks/issues/2522).

If you followed the old instructions, you have the old .dll in your store. Follow either option below and update your config accordingly.

If you ever do go back to winetricks once that's fixed upstream, clear `~/.cache/winetricks/d3dcompiler_47` first. winetricks happily reinstalls the old cached cab otherwise, even with `--force`.

## Option 1: Let Nix fetch it

This flake's overlay provides `pkgs.xivlauncher-d3dcompiler-url`. Point `d3dcompiler.package` at it.

```nix
# home/xivlauncher.nix
{ inputs, pkgs, ... }:
{
  imports = [ inputs.xiv-flake.homeManagerModules.default ];

  nixpkgs.overlays = [ inputs.xiv-flake.overlays.default ];

  programs.xivlauncher = {
    enable = true;
    game = {
      reshade = {
        enable = true;
        d3dcompiler = {
          enable = true;
          package = pkgs.xivlauncher-d3dcompiler-url; # this option
        };
      };
    };
  };
}
```

As above, with `home-manager.useGlobalPkgs = true` the overlay goes in your NixOS config instead.

Don't want the overlay? This works too.

```nix
package = pkgs.callPackage "${inputs.xiv-flake}/pkgs/d3d-url.nix" { };
```

### When Microsoft moves the URL

The build will fail to download. You can override the URL without waiting for this flake to update.

```nix
# you only need this if the cab has changed:
package = pkgs.xivlauncher-d3dcompiler-url.override {
  url = "https://download.microsoft.com/download/.../\<whatever\>.cab";
  # member = "fil3585cb2ea5db13cc0838f8d06b5c9679"; # name of the x64 .dll inside the cab
  # hash = "sha256-..."; # hash of the extracted .dll, not the cab
};
```

Or just fall back to option 2.

### Finding the URL and member ID

**This section only applies if 1. Using the package above results in a build failure OR 2. There is a newer version and this flake has not updated to it yet.**

All of this can be read straight out of Microsoft's own SDK installer, no Windows or Wine required. Grab the tools first.

```sh
nix shell nixpkgs#cabextract nixpkgs#msitools nixpkgs#curl
```

**1. Find the SDK installer.** Every Windows SDK release ships a small bootstrapper, `winsdksetup.exe`, at a URL that looks like this.

```
https://download.microsoft.com/download/<guid>/KIT_BUNDLE_WINDOWSSDK_MEDIACREATION/winsdksetup.exe
```

You can get it from the download link on Microsoft's [Windows SDK page](https://developer.microsoft.com/windows/downloads/windows-sdk/), or from the `InstallerUrl` in the SDK's [winget manifest](https://github.com/microsoft/winget-pkgs/tree/master/manifests/m/Microsoft/WindowsSDK). Everything the bootstrapper downloads lives in the `Installers/` folder next to it, which is where the cab URL comes from. For SDK 10.0.28000.2705, that's this.

```sh
base=https://download.microsoft.com/download/38ab8f6d-3676-4860-ae84-3361308b9d7f/KIT_BUNDLE_WINDOWSSDK_MEDIACREATION
```

**2. Grab the MSI that ships the .dll.** That's `Windows SDK for Windows Store Apps Tools-x86_en-us.msi`. Ignore the x86 in its name, it carries every architecture's copy.

```sh
curl -L -o tools.msi "$base/Installers/Windows%20SDK%20for%20Windows%20Store%20Apps%20Tools-x86_en-us.msi"
```

If that 404s, the MSI may have been renamed. The bootstrapper carries a manifest of every MSI and cab it downloads, so you can look for it there.

```sh
curl -LO "$base/winsdksetup.exe"
cabextract -F 0 winsdksetup.exe    # file "0" is the installer's manifest (XML)
grep -o 'Installers\\[^"]*\.msi' 0 | sort -u
```

**3. Look up the member.** Inside the cabs, files aren't stored under their real names. They're stored under their key in the MSI's `File` table (the `fil...` names). The MSI's other tables map each key to a real name, an install directory and the cab it's in. Save this as `find-d3d.awk`.

```awk
BEGIN { FS = "\t" }
{ sub(/\r$/, "") }
FILENAME == "Directory.tsv" { n = $3; sub(/.*\|/, "", n); sub(/:.*/, "", n); name[$1] = n; parent[$1] = $2 }
FILENAME == "Component.tsv" { dir[$1] = $3 }
FILENAME == "Media.tsv" && $4 != "" { last[++m] = $2; cab[m] = $4 }
FILENAME == "File.tsv" && tolower($3) ~ /d3dcompiler_47\.dll$/ {
  path = ""
  for (d = dir[$2]; d != "" && d != "TARGETDIR"; d = parent[d]) if (name[d] != ".") path = name[d] "/" path
  for (i = 1; i <= m; i++) if ($8 + 0 <= last[i] + 0) break
  print $1, cab[i], path
}
```

It builds each file's install path by walking its `Component` → `Directory` chain, and finds its cab by checking which `Media` entry's `LastSequence` covers the file's `Sequence` number. Run it against the exported tables.

```sh
for t in File Component Directory Media; do msiinfo export tools.msi $t > $t.tsv; done
awk -f find-d3d.awk Directory.tsv Component.tsv Media.tsv File.tsv
```

For SDK 10.0.28000.2705, you get this.

```
fil0d3f984977487cd87127d614f654195b 69661e20556b3ca9456b946c2c881ddd.cab Windows Kits/10/bin/10.0.28000.0/x64/
fil535caf0510df46eac7eb644d32c36698 b82881a61b7477bd4eb5de2cd5037fe2.cab Windows Kits/10/bin/10.0.28000.0/arm64/
filbc0d69b8fac3b2f98c9b18fb7b476d2b e3d1b35aecfccda1b4af6fe5988ac4be.cab Windows Kits/10/bin/10.0.28000.0/x86/
fila319f706acfa16d6707473ebf29bdc7f 2630bae9681db6a9f6722366f47d055c.cab Windows Kits/10/Redist/D3D/x86/
fil3585cb2ea5db13cc0838f8d06b5c9679 61d57a7a82309cd161a854a6f4619e52.cab Windows Kits/10/Redist/D3D/x64/
fil90e4d186f0766cc07afe88a70587a74f 68de71e3e2fb9941ee5b7c77500c0508.cab Windows Kits/10/Redist/D3D/arm64/
```

You want the one under `Redist/D3D/x64/`. The first column is your `member`, and the URL is `$base/Installers/` followed by the second column.

As for `hash`, set it to `pkgs.lib.fakeHash`, rebuild, and take the real hash from the error. Or follow option 2 below with the new URL and member, and use `nix hash file`.

## Option 2: Bring your own

To do so, run `nix shell nixpkgs#cabextract nixpkgs#file` in a terminal session.

Next, run this.

```sh
curl -LO https://download.microsoft.com/download/\<guid\>/KIT_BUNDLE_WINDOWSSDK_MEDIACREATION/Installers/\<whatever\>.cab
cabextract -L -F \<guid\> \<whatever\>.cab
mv \<guid\> d3dcompiler_47.dll
file d3dcompiler_47.dll    # must say PE32+ ... x86-64
```

The above downloads the Windows SDK cab containing the library, and extracts the 64-bit `d3dcompiler_47.dll` from it into your current directory. If you have a `d3dcompiler_47.dll` from elsewhere that you'd rather use, that works too, as long as it's the 64-bit one.

Finally, add it to the Nix store.

```sh
nix-store --add-fixed sha256 d3dcompiler_47.dll
nix hash file d3dcompiler_47.dll
```

You should now also have the hash for the desired `d3dcompiler_47.dll`. For the .dll above, that's `sha256-PlbBoIZ6oEy8qUizZk/KxdUSdYZc0ESkWj/WzmNu6RQ=`. Hold on to this hash.

Now tell Nix to set it up for you.

```nix
# home/xivlauncher.nix
{ inputs, pkgs, ... }:
{

  imports = [ inputs.xiv-flake.homeManagerModules.default ];
  programs.xivlauncher = {
    enable = true;
    game = {
      reshade = {
        enable = true;
        d3dcompiler = {
          enable = true;
          hash = "sha256-AAA...";
        };
      };
    };
  };
}
```

Do note that the .dll is not part of your config. It lives only in your Nix store, so on a fresh machine you'll need to add it again before rebuilding.

Once that's done, head back to [Enabling ReShade](./enabling-reshade.md#checking-it-works) to check it works.

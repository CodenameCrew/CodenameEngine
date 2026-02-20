{
  pkgs ? import (fetchTarball "https://github.com/NixOS/nixpkgs/archive/14e02be4774fdb74b2d81ab2beb7a15b1e6eda07.tar.gz") { },
}:
let
  libs =
    with pkgs;
    [
      SDL2
      pkg-config
      openal
      alsa-lib
      libvlc
      libpulseaudio
      libGL
    ]
    ++ (with xorg; [
      libX11
      libXext
      libXinerama
      libXi
      libXrandr
    ]);
in
pkgs.mkShell {
  name = "CodenameEngine";

  packages = with pkgs; [
    haxe
    neko
    kdePackages.qttools
  ];

  buildInputs = libs;

  LD_LIBRARY_PATH = pkgs.lib.makeLibraryPath libs;

  shellHook = ''
    ./building/setup-unix.sh
  '';
}

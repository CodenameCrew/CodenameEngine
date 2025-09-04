{ }:
let
  pkgs = import (builtins.fetchTarball {
    url = "https://github.com/NixOS/nixpkgs/archive/c407032be28ca2236f45c49cfb2b8b3885294f7f.tar.gz";
  }) { };

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
    libsForQt5.qttools
  ];

  buildInputs = libs;

  LD_LIBRARY_PATH = pkgs.lib.makeLibraryPath libs;

  shellHook = ''
    source update.sh
  '';
}

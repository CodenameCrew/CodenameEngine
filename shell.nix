{
  pkgs ? import <nixpkgs> {
    overlays = [
      (final: prev: {
        # Haxe does not compile properly using the overlay
        # below, due to an OCaml error. Do note that the patches
        # have been removed as a result of an outdated patch.
        #
        # haxe = prev.haxe.overrideAttrs (old: {
        #   version = "4.3.7";
        #   src = prev.fetchgit {
        #     url = "https://github.com/HaxeFoundation/haxe.git";
        #     tag = "4.3.7";
        #     hash = "sha256-sQb7MCoH2dZOvNmDQ9P0yFYrSXYOMn4FS/jlyjth39Y=";
        #     fetchSubmodules = true;
        #   };
        #   patches = [ ];
        # });
      })
    ];
    config = { };
  },
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

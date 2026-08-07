{
  description = "Basic flake for Codename Engine, primarily useful for development";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixpkgs-unstable";
    systems.url = "github:nix-systems/default";
    flake-compat = {
      url = "github:NixOS/flake-compat";
      flake = false;
    };
  };

  outputs =
    { nixpkgs, systems, ... }:
    let
      forEachSystem = nixpkgs.lib.genAttrs (import systems);
    in
    {
      devShells = forEachSystem (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        {
          default = pkgs.mkShell rec {
            name = "cne";
            buildInputs = with pkgs; [
              kdePackages.qttools
              openal
              libpulseaudio
              libvlc
              libGL
              libx11
              libxext
              libxinerama
              libxi
              libxrandr
              SDL2
            ];
            nativeBuildInputs = with pkgs; [
              haxe
              neko
            ];
            shellHook = ''
              ./building/setup-unix.sh
            '';
            LD_LIBRARY_PATH = pkgs.lib.makeLibraryPath buildInputs;
          };
        }
      );
    };
}

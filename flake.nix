{
  description = "Basic flake for Codename Engine, primarily useful for development";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    flake-compat = {
      url = "github:NixOS/flake-compat";
      flake = false;
    };
  };

  outputs =
    { nixpkgs, ... }:
    let
      forEachSystem =
        function:
        nixpkgs.lib.genAttrs [ "aarch-darwin" "aarch64-linux" "x86_64-darwin" "x86_64-linux" ] (
          system:
          function (
            nixpkgs.legacyPackages.${system}.extend (
              final: prev: {
                # We need to configure mbedtls_2 for Haxe manually, forcing a rebuild with different
                # parameters.
                mbedtls_2 = prev.mbedtls_2.overrideAttrs {
                  # ...and that includes removing all known vulnerabilities. As of writing, the only
                  # assigned vulnerability is that mbedtls_2 is no longer developed. Nix will refuse
                  # to build packages if they have this value filled in.
                  meta.knownVulnerabilities = [ ];
                  # Without this, Nix will attempt to build the package and test it. The tests
                  # themselves unfortunately fail at the moment, so we need to skip them to use
                  # mbedtls_2 successfully.
                  doCheck = false;
                };
              }
            )
          )
        );
    in
    {
      devShells = forEachSystem (pkgs: {
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
      });
    };
}

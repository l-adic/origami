{
  inputs = {
    haskellNix = {
      url = "github:input-output-hk/haskell.nix";
      # prevent nix-direnv from fetching stackage
      inputs.stackage.url = "github:input-output-hk/empty-flake";
    };
    nixpkgs.follows = "haskellNix/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";


    # for Ormolu Live
    ghc-wasm-meta.url = "gitlab:ghc/ghc-wasm-meta?host=gitlab.haskell.org";


  };
  outputs = inputs@{ self, nixpkgs, flake-utils, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          inherit (inputs.haskellNix) config;
          overlays = [ inputs.haskellNix.overlay ];
        };
        inherit (pkgs) lib haskell-nix;
        inherit (haskell-nix) haskellLib;

        ghcVersions = [ "ghc964" ];
        defaultGHCVersion = builtins.head ghcVersions;
        perGHC = lib.genAttrs ghcVersions (ghcVersion:
          let
            hsPkgs = pkgs.haskell-nix.cabalProject {
              src = ./.;
              compiler-nix-name = ghcVersion;
            };
            packages = lib.recurseIntoAttrs ({
              dev = { inherit hsPkgs; };
            });
             
          in packages
        );
        defaultGHC = perGHC.${defaultGHCVersion};

        wasmSolver = import wasm-solver/default.nix {
          inherit pkgs inputs defaultGHC;
        };
      in
      {
        devShells = {
          default = defaultGHC.dev.hsPkgs.shellFor {
            tools = {
              cabal = "latest";
            };
            buildInputs = with pkgs; [
              haskellPackages.ormolu_0_5_2_0
              haskellPackages.cabal-fmt
            ];

            withHoogle = false;
            exactDeps = false;
          };
          wasmSolver = wasmSolver.shell;
          ghcWasm = wasmSolver.ghcWasmShell;
        };
        legacyPackages = defaultGHC // perGHC;
      });
  nixConfig = {
    extra-substituters = [
      "https://cache.iog.io"
      "https://tweag-ormolu.cachix.org"
    ];
    extra-trusted-public-keys = [
      "hydra.iohk.io:f/Ea+s+dFdN+3Y/G+FDgSq+a5NEWhJGzdjvKNGv0/EQ="
      "tweag-ormolu.cachix.org-1:3O4XG3o4AGquSwzzmhF6lov58PYG6j9zHcTDiROqkjM="
    ];
  };
}

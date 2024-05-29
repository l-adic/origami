{ pkgs, inputs, defaultGHC }:

let
  inherit (pkgs) system lib;

  metadata = builtins.toJSON {
    inherit (inputs.self.packages.${system}.default) version;
    inherit (inputs.self) rev;
    ghcAPIVersion =
      defaultGHC.dev.hsPkgs.ghc-lib-parser.components.library.version;
  };

  ghcWasmDeps = [ inputs.ghc-wasm-meta.packages.${system}.all_9_8 ];

in

{
  shell = pkgs.mkShell { packages = [ ghcWasmDeps ]; };
}

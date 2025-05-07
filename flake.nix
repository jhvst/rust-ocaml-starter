{

  inputs = {
    cargo2nix.url = "github:cargo2nix/cargo2nix";
    flake-parts.url = "github:hercules-ci/flake-parts";
    nixpkgs.url = "github:nixos/nixpkgs/nixos-24.11";
  };

  outputs = { ... }@inputs:
    inputs.flake-parts.lib.mkFlake { inherit inputs; } {

      systems = inputs.nixpkgs.lib.systems.flakeExposed;
      imports = [ ];

      perSystem = { pkgs, system, ... }:

        let
          rustPkgs = pkgs.rustBuilder.makePackageSet {
            packageOverrides = pkgs: pkgs.rustBuilder.overrides.all ++ [
              (pkgs.rustBuilder.rustLib.makeOverride {
                name = "ocaml-boxroot-sys";
                overrideAttrs = drv: {
                  buildInputs = drv.buildInputs ++ [ pkgs.ocaml-ng.ocamlPackages_4_14.ocaml ];
                };
              })
              (pkgs.rustBuilder.rustLib.makeOverride {
                name = "ocaml-sys";
                overrideAttrs = drv: {
                  buildInputs = drv.buildInputs ++ [ pkgs.ocaml-ng.ocamlPackages_4_14.ocaml ];
                };
              })
              (pkgs.rustBuilder.rustLib.makeOverride {
                name = "rust-ocaml-starter";
                overrideAttrs = drv: {
                  buildInputs = drv.buildInputs ++ [ pkgs.dune_3 pkgs.ocaml-ng.ocamlPackages_4_14.ocaml ];
                };

              })
            ];
            rustVersion = "1.77.0";
            packageFun = import ./Cargo.nix;
          };

          workspaceShell = (rustPkgs.workspaceShell {
            buildInputs = [ pkgs.dune_3 pkgs.ocaml-ng.ocamlPackages_4_14.ocaml ];
          });

        in

        {

          _module.args.pkgs = import inputs.nixpkgs {
            inherit system;
            overlays = [
              inputs.cargo2nix.overlays.default
            ];
            config = { };
          };


          devShells = {
            default = workspaceShell;
          };

          packages = {
            rust-ocaml-starter = (rustPkgs.workspace.rust-ocaml-starter { });
          };
        };

    };
}
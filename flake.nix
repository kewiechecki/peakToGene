{
  description = "Flake to build + develop peakToGene R package";

  nixConfig = {
    bash-prompt = "\[peakToGene$(__git_ps1 \" (%s)\")\]$ ";
  };

  inputs = {
    nixpkgs.url     = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";

  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs  = import nixpkgs { inherit system; config.allowUnfree = true; };
        rpkgs = pkgs.rPackages;

        myPkg = rpkgs.buildRPackage rec {
          name    = "peakToGene";
          pname    = "peakToGene";
          version = "0.0.2";
          src     = ./.;

          # R‐side dependencies:
          propagatedBuildInputs = [
              rpkgs.GenomicFeatures
              rpkgs.GenomicRanges
			  rpkgs.rtracklayer
          ];

          nativeBuildInputs = [
            pkgs.R
            pkgs.pkg-config
          ];

          # C‑library dependencies
          buildInputs = [
			pkgs.libpng
          ];

		  preBuild = ''
		  make build
		  #mv build $out
		  '';

          #installPhase = ''
          #  # install the tarball into $out, with dirfns present
          #  R CMD INSTALL --library=$out .
          #'';

          # re‑enable Nix’s R-wrapper so it injects R_LD_LIBRARY_PATH
          dontUseSetLibPath = false;

          meta = with pkgs.lib; {
            description = "…";
            license     = licenses.mit;
            maintainers = [ maintainers.kewiechecki ];
          };
        };
      in rec {
        # 1) allow `nix build` with no extra attr:
        defaultPackage = myPkg;

        # 2) drop you into a shell for interactive R work:
        devShells = {
          default = pkgs.mkShell {
            name = "peakToGene-shell";
            buildInputs = [
              pkgs.git
              pkgs.R
              rpkgs.circlize
              rpkgs.ComplexHeatmap
			  pkgs.libpng
            ];
            shellHook = ''
source ${pkgs.git}/share/bash-completion/completions/git-prompt.sh

export LD_LIBRARY_PATH="${pkgs.libpng.out}/lib:$LD_LIBRARY_PATH"
export PKG_CONFIG_PATH="${pkgs.libpng.out}/lib:$PKG_CONFIG_PATH"
            '';
          };
        };
      });
}


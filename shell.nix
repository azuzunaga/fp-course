# This was only tested against revision ac2d18a7353cd3ac1ba4b5993f2776fe0c5eedc9
# of https://gitlab.haskell.org/ghc/ghc
let
  nixpkgs = builtins.fetchTarball {
    url =
      "https://github.com/NixOS/nixpkgs/archive/7e003d7fb9eff8ecb84405360c75c716cdd1f79f.tar.gz";
    sha256 = "08y8pmz7xa58mrk52nafgnnrryxsmya9qaab3nccg18jifs5gyal";
  };

  config.allowBroken = true;

  pkgs = import nixpkgs { inherit config; };

in pkgs.mkShell {
  nativeBuildInputs = [
    pkgs.automake
    pkgs.autoconf
    pkgs.python3
    (pkgs.haskell.packages.ghc902.ghcWithPackages
      (p: [ p.alex p.happy p.haddock p.haskell-language-server ]))
    pkgs.sphinx
    pkgs.texlive.combined.scheme-small
    pkgs.gmp
  ];
}

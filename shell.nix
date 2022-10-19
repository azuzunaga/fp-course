# From https://gist.github.com/Gabriel439/4c0c2a81cc0e089043ed33da5b01fee7

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
      (p: [ p.ghc p.alex p.happy p.haddock p.haskell-language-server ]))
    pkgs.sphinx
    pkgs.texlive.combined.scheme-small
    pkgs.gmp
    pkgs.nixfmt
  ];
}

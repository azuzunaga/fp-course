self: super: {
  haskell =
    super.haskell
    // {
      packages =
        super.haskell.packages
        // {
          ghc924 =
            super.haskell.packages.ghc924
            // {
              cabal-install = super.haskell.packages.ghc924.cabal-install.overrideAttrs (old: {
                patches =
                  old.patches
                  or []
                  ++ [
                    ../patches/cabal-install/0001-Backport-supporting-submodules-in-git-source-reposit.patch
                  ];
              });
            };
        };
    };
}

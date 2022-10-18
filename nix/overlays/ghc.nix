self: super: {
  haskell =
    super.haskell
    // {
      compiler =
        super.haskell.compiler
        // {
          ghc924 =
            (super.haskell.compiler.ghc924.override {
              # since we have to recompile the compiler, let's not sphinx the
              # ghc-itself docs to save time.
              enableDocs = false;
            })
            .overrideDerivation (drv: {
              patches =
                drv.patches
                ++ [
                  # https://github.com/haskell/haddock/pull/1525
                  ../patches/ghc/0001-Fix-line-wrapping-in-instances-list.patch
                ];
            });
        };
    };
}

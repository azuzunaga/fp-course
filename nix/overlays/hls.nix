{inputs}: self: super: let
  inherit (inputs) hls;
  # The haskell-language-server input is a flake with an overlay.
  # We'll apply that overlay to the self/super here, which is our nixpkgs for
  # Haskell, which has all of the GHC versions in which we're interested.

  # this is an overlay we added in a patch to deal with Nix segfaulting due to gitignoreSource
  overlay = hls.overlays.noGitignore self super;

  hlsHpkgs = with self.haskell.lib;
    (overlay.hlsHpkgs "ghc924").extend (hself: hsuper: {
      # HLS pins implicit-hie-cradle to an old tarball for some reason, which has
      # too tight bounds on time and bytestring. Their strategy of grabbing
      # things from hackage as flake inputs is jacked in the presence of metadata
      # revisions: 0.5.0.0 on hackage as it is today works properly but the
      # tarball doesn't have the updated bounds.
      #
      # So we have to callHackage in an overlay over their overlay instead of
      # just changing their flake input.
      #
      # For lsp and lsp-types, the versions they're using seem to be older, so
      # let's just force them onto the ones we are already building anyway.
      implicit-hie-cradle = hself.callHackage "implicit-hie-cradle" "0.5.0.0" {};
      lsp = hsuper.callHackage "lsp" "1.6.0.0" {};
      lsp-types = hsuper.callHackage "lsp-types" "1.6.0.0" {};
    });

  # Copied from haskell-language-server flake because they don't put it on the
  # overlay.
  mkExe = hlsHpkgs:
    with self.haskell.lib;
      (enableSharedExecutables (overrideCabal hlsHpkgs.haskell-language-server
        (_: {
          postInstall = ''
            remove-references-to -t ${hlsHpkgs.shake.data} $out/bin/haskell-language-server
            remove-references-to -t ${hlsHpkgs.js-jquery.data} $out/bin/haskell-language-server
            remove-references-to -t ${hlsHpkgs.js-dgtable.data} $out/bin/haskell-language-server
            remove-references-to -t ${hlsHpkgs.js-flot.data} $out/bin/haskell-language-server
          '';
        })))
      .overrideAttrs (old: {
        pname = old.pname + "-ghc${hlsHpkgs.ghc.version}";
      });

  haskell-language-server = mkExe hlsHpkgs;
in {
  inherit haskell-language-server;
}

rec {
  # Take the newer of 2 Haskell packages.
  # If they are equal, take the first argument.
  #
  # The version of the second package is explicitly given in order to avoid
  # evaluating the package (which involves callCabal2nix
  # import-from-derivation) if we don't need it.
  newer = hsPkgA: {
    version,
    package,
  }: let
    cmp = builtins.compareVersions hsPkgA.version version;
  in
    if cmp == -1
    then package
    else hsPkgA;

  # Use in a Haskell overlay with hself and hsuper: take the hsPkgName with at
  # least hsPkgVersion. If the one in the package set is less than the version,
  # then that package is replaced by the one from hackage at the specified version.
  #
  # If the package set does not contain anything of the given name, then hackage
  # is used.
  atLeast = hself: hsuper: hsPkgName: hsPkgVersion: callHackageArgs:
    if builtins.hasAttr hsPkgName hsuper
    then
      newer (builtins.getAttr hsPkgName hsuper)
      {
        version = hsPkgVersion;
        package = hself.callHackage hsPkgName hsPkgVersion callHackageArgs;
      }
    else hself.callHackage hsPkgName hsPkgVersion callHackageArgs;

  # Compose the second overlay 'over' on top of the first overlay 'base'.
  composeOverlays = base: over: hself: hsuper: let
    lower = hsuper // base hself hsuper;
    upper = lower // over hself lower;
  in
    upper;

  # Like composeOverlays but you give a neme for the overlay and its instantiation
  # is put in the overlayPackages attribute of the resulting attr set.
  # The namedOverlay argument has keys overlay which is the overlay function
  # itself, and name which is the name of the overlay (must be unique among the
  # entire composition).
  composeNamedOverlays = base: namedOverlay: hself: hsuper: let
    lower = hsuper // base hself hsuper;
    overlayAttrs = namedOverlay.overlay hself lower;
    upper = lower // overlayAttrs;
    overlayPackages = (upper.overlayPackages or {}) // {${namedOverlay.name} = overlayAttrs;};
  in
    upper // {inherit overlayPackages;};
}

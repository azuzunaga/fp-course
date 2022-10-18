# Overlay which checks whether Haskell packages are accidentally being
# downgraded. Evaluate the `haskellPackageVersions` attribute with
# `builtins.deepSeq` to print warnings.
#
# This overlay must be applied before the Haskell package set is overridden, so
# that we compare against vanilla Nixpkgs package versions.
pkgsFinal: pkgsPrev: let
  inherit (pkgsPrev) lib;

  allowedDowngrades = {
    # "package-name" = "Reason why we allow downgrading";
  };

  # Package sets to compare
  hsPrev = pkgsPrev.haskell.packages.ghc924;
  hsFinal = pkgsFinal.haskell.packages.ghc924;

  # Mapping from package names to list of versions used. When evaluated, will
  # print warnings for packages being downgraded.
  packageVersions = warnOnDowngrade (collectVersions [hsPrev hsFinal]);

  # Given a list of Haskell package sets, return a mapping from package names to
  # lists of versions used.
  #
  # { lucid = <derivation>; ... } -> { lucid = [ "2.11.0" "2.11.1" ]; ... }
  collectVersions = packageSets:
    lib.zipAttrsWith
    (
      name: packages:
        lib.foldl'
        (
          versions: package:
            if package ? version && !(lib.elem package.version versions)
            then versions ++ [package.version]
            else versions
        )
        []
        packages
    )
    packageSets;

  # Given a mapping from package names to pairs of versions, print a warning
  # when we're accidentally downgrading.
  warnOnDowngrade = packages:
    builtins.deepSeq
    (
      lib.mapAttrs
      (
        name: versions @ {
          nixpkgsVersion,
          mwbVersion,
        }:
          if builtins.compareVersions nixpkgsVersion mwbVersion == 1
          then
            lib.warn
            "${name} downgraded from version ${nixpkgsVersion} to ${mwbVersion}"
            versions
          else versions
      )
      (filterDowngrades packages)
    )
    packages;

  # Given a mapping from package names to lists of versions used, keep
  # packages which have been downgraded.
  filterDowngrades = packages:
    lib.pipe packages [
      (lib.filterAttrs
        (
          name: versions:
            lib.length versions
            == 2
            && !(lib.elem name (lib.attrNames allowedDowngrades))
        ))
      (lib.mapAttrs
        (name: versions: {
          nixpkgsVersion = lib.elemAt versions 0;
          mwbVersion = lib.elemAt versions 1;
        }))
    ];
in {
  haskellPackageVersions = packageVersions;
}

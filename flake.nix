# Nix Flakes allow the result of evaluating Nix expressions to be cached.
# Because we have some fairly complex Nix expressions, this can save 10-15
# seconds every time you enter a `nix-shell`.
#
# See: https://nixos.org/manual/nix/stable/command-ref/new-cli/nix3-flake.html#flake-format
{
  description = "The Mercury kitchen sink";

  # Update the lockfile to reflect new or changed inputs with `nix flake lock`.
  inputs.nixpkgs = {
    type = "github";
    owner = "matthewbauer";
    repo = "nixpkgs";
    ref = "matthewbauer/ghc922-backport";
  };

  # The nixpkgs used to get GHC and Haskell packages is not necessarily the
  # same as the one used for everything else that nix provisions. This
  # allows us to more quickly bring in new GHC versions without causing big
  # rebuilds.
  inputs.nixpkgs-haskell = {
    type = "github";
    owner = "avieth";
    repo = "nixpkgs";
    ref = "avieth/merge-haskell-updates-master";
  };

  # Using "file" here as a workaround since alternatives cause issues.
  # all-cabal-hashes is a big repo which can break things.

  # "github" has hash mismatch on some machines, probably caused either
  # by github’s compression corruption or local decompression corruption.
  # see https://mercurytechnologies.slack.com/archives/C03HPJEGW2C/p1661364622910359

  # "git" also can have hash mismatch issues, probably also caused by data corruption
  # also just generally slow, esp. in updating just because of how many git objects there are.
  # see https://mercurytechnologies.slack.com/archives/C01QJRR7E23/p1661514767303749
  inputs.hackage-index.type = "file";
  inputs.hackage-index.flake = false;

  inputs.hackage-index.url = "https://api.github.com/repos/commercialhaskell/all-cabal-hashes/tarball/97c53fc5c6af9939a0ea45967dd8359294faad44";

  # this is master at approximately 1.8.0.0, patched to add a noGitignore
  # overlay to avoid segfaults in Nix caused by gitignoreSource. jacked.
  #
  # See https://github.com/MercuryTechnologies/mercury-web-backend/pull/7873
  # for further context on the segfaults.
  inputs.hls = {
    type = "github";
    owner = "MercuryTechnologies";
    repo = "haskell-language-server";
    ref = "mercury/1.8.0.0";
    # this is intentionally breaking HLS trying to have its own cabal hashes
    # (which it does not use anyway?) so nix doesn't waste developer time
    # fetching something that should be done by our some-cabal-hashes system
    # instead
    inputs.all-cabal-hashes-unpacked.follows = "flake-compat";
  };

  inputs.haskell-nix = {
    type = "github";
    owner = "MercuryTechnologies";
    repo = "haskell.nix";
    ref = "matt/ref-or-rev-ours";
    flake = false;
  };

  inputs.hackage-nix = {
    type = "github";
    owner = "input-output-hk";
    repo = "hackage.nix";
    ref = "master";
    flake = false;
  };

  inputs.flake-compat = {
    type = "github";
    owner = "matthewbauer";
    repo = "flake-compat";
    ref = "support-fetching-file-type-flakes";
    flake = false;
  };

  outputs = {
    self,
    nixpkgs,
    nixpkgs-haskell,
    ...
  } @ inputs': let
    # Unfortunately, flake-compat has an incompatibility where single file inputs are derivations instead of sources.
    # To make sure our hashes are the same between flake and non-flake, we need use flake-compat just for hackage-index
    # even though we already have it in inputs’ above. This ensures we have cache hits on nix develop and
    # nix-shell.
    mkInputs =
      forAllSystems (system:
        inputs' // {hackage-index = (import ./nix/get-inputs.nix {inherit system;}).hackage-index;});

    defaultNix = import ./default.nix;
    shellNix = import ./shell.nix;
    supportedSystems = ["x86_64-linux" "x86_64-darwin" "aarch64-darwin"];
    supportedCompilers = ["ghc924"];
    defaultCompiler = "ghc924";
    forAllSystems = f: nixpkgs.lib.genAttrs supportedSystems (system: f system);
    forAllCompilers = f: nixpkgs.lib.genAttrs supportedCompilers (compilerName: f compilerName);
    #nixpkgsForSystem = system: nixpkgsSrc: config:
    #  import nixpkgsSrc (config // { inherit system; });
    mkDefaultFor = forAllSystems (system:
      forAllCompilers (compilerName:
        defaultNix {
          inherit system compilerName;
          inputs = mkInputs.${system};
          nixpkgs = import nixpkgs;
          nixpkgs-haskell = import nixpkgs-haskell;
          revision = self.shortRev or "FAKE_GIT_SHA1";
          disable-optimization = false;
          werror = true;
          doCheck = true;
          bypassMigrationMatchingCheck = true;
          doHoogle = false;
          doHaddock = false;
          hlint = false;
          formatCheck = false;
        }));
    # like mkDefaultFor, but with some stricter checks
    mkHydraDefaultFor = forAllSystems (system:
      forAllCompilers (compilerName:
        defaultNix {
          inherit system compilerName;
          inputs = mkInputs.${system};
          nixpkgs = import nixpkgs;
          nixpkgs-haskell = import nixpkgs-haskell;
          revision = self.shortRev or "FAKE_GIT_SHA1";
          disable-optimization = false;
          werror = true;
          doCheck = true;
          bypassMigrationMatchingCheck = false;
          doHoogle = true;
          doHaddock = true;
          hlint = true;
          formatCheck = true;
        }));
    mkShellFor = system: compilerName: shellArgs:
      shellNix ({
          inherit system compilerName;
          inputs = mkInputs.${system};
          nixpkgs = import nixpkgs;
          nixpkgs-haskell = import nixpkgs-haskell;
          withHoogle = false;
          # Do not install the hooks. The intended use of the flake's shell is
          # to not enter a shell but to use it to run commands and exit, so
          # setting hooks each time would not be appropriate.
          # FIXME offer a make command to install the hooks.
          withShellHooks = false;
          revision = self.shortRev or "FAKE_GIT_SHA1";
          disable-optimization = false;
          werror = false;
          doCheck = true;
          bypassMigrationMatchingCheck = true;
          doHoogle = false;
          doHaddock = false;
          hlint = false;
          formatCheck = false;
        }
        // shellArgs);
    mkHaskellNixShellFor = system: compilerName:
      (import ./nix/haskell.nix {
        inherit system compilerName;
        inputs = mkInputs.${system};
      })
      .shell;

    # useful for avoiding conflicts between generated attr sets
    genAttrsWithPrefix = prefix: list: f:
      builtins.listToAttrs (map (x: {
          name = "${prefix}-${x}";
          value = f x;
        })
        list);
  in {
    packages = forAllSystems (system:
      {
        default = self.packages.${system}.mwb;
        mwb = self.packages.${system}."mwb-${defaultCompiler}";
      }
      // genAttrsWithPrefix "mwb" supportedCompilers (compilerName: mkDefaultFor.${system}.${compilerName}.build));

    # Enter with `nix develop`.
    devShells = forAllSystems (system: let
      shellsHooks = genAttrsWithPrefix "mwb" supportedCompilers (compilerName: mkShellFor system compilerName {withShellHooks = true;});
      shellsNoHooks = genAttrsWithPrefix "mwb-nohooks" supportedCompilers (compilerName: mkShellFor system compilerName {withShellHooks = false;});
      haskellNixShell = genAttrsWithPrefix "mwb-haskell-nix" supportedCompilers (compilerName: mkHaskellNixShellFor system compilerName);
    in
      shellsHooks
      // shellsNoHooks
      // haskellNixShell
      // {
        default = shellsHooks."mwb-${defaultCompiler}";
      });

    checks = forAllSystems (system: {
      inherit (self.packages.${system}) mwb;
      inherit (mkDefaultFor.${system}.${defaultCompiler}) checkFormatMWB hlintMWB;
    });

    # Meant to eventually replace release.nix
    hydraJobs = {
      inherit (mkHydraDefaultFor.x86_64-linux.${defaultCompiler}) build gems libical;
    };
  };

  nixConfig.extra-substituters = ["https://cache.mercury.com" "https://cache.iog.io"];
  nixConfig.extra-trusted-public-keys = ["cache.mercury.com:yhfFlgvqtv0cAxzflJ0aZW3mbulx4+5EOZm6k3oML+I=" "hydra.iohk.io:f/Ea+s+dFdN+3Y/G+FDgSq+a5NEWhJGzdjvKNGv0/EQ="];
  nixConfig.allow-import-from-derivation = true; # needed for cabal2nix
  nixConfig.bash-prompt = "\\n\\[\\e[1;32m\\][mwb-dev:\\w]\\$\\[\\e[0m\\] ";
}

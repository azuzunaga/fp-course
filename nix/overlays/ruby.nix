self: super: {
  bundler = super.bundler.overrideAttrs (old: {
    dontBuild = false;
    patches =
      old.patches
      or []
      ++ [
        ../patches/ruby/0001-Silence-sudo-warnings-about-nix-files.patch
      ];
  });
}

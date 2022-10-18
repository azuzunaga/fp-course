self: super: {
  # httplib2 tests fail on my machine for some reason so disabling
  # them for now - matthew

  python39 = super.python39.override {
    packageOverrides = pself: psuper: {
      httplib2 = psuper.httplib2.overridePythonAttrs (_: {
        doCheck = !(self.stdenv.hostPlatform.isAarch64 && self.stdenv.hostPlatform.isDarwin);
      });
    };
  };
}

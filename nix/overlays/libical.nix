self: super: {
  libical = super.libical.overrideAttrs (old: {
    # libical is marked broken on darwin.
    # https://github.com/NixOS/nixpkgs/pull/173671
    meta = old.meta // {broken = false;};
    outputs = [
      "out"
      "dev"
    ];
    doInstallCheck = false;
    cmakeFlags = [
      "-DICAL_GLIB=False"
      "-DICAL_GLIB_VAPI=False"
      "-DICAL_BUILD_DOCS=False"
      "-DENABLE_GTK_DOC=False"
      "-DWITH_CXX_BINDINGS=False"
    ];
    nativeBuildInputs = [
      self.perl
      self.cmake
    ];
  });
}

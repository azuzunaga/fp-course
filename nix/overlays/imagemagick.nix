self: super: {
  imagemagickBig = super.imagemagickBig.overrideAttrs (old: {doCheck = false;});
}

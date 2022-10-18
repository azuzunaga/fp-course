self: super: {
  # netcdf tests don’t work on aarch64-darwin
  # needed because: postgis -> gdal -> netcdf
  netcdf =
    if (self.stdenv.hostPlatform.isDarwin && self.stdenv.hostPlatform.isAarch64)
    then super.netcdf.overrideAttrs (_: {doCheck = false;})
    else super.netcdf;
}

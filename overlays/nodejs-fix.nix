self: super: {
  nodejs_22 = super.nodejs_22.overrideAttrs (oldAttrs: {
    doCheck = false;
    doInstallCheck = false;
  });
}

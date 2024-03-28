# Build an SD (installer) image
build-sd:
  nix build '.#nixosConfigurations.default.config.system.build.sdImage'

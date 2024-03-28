{
  description = "";

  inputs = {
    nixos.url = "nixpkgs/23.11"; # for live media
  };

  outputs = { self, nixpkgs, nixos }@inputs:
  let
    devSystems = [
      "x86_64-linux"
      "aarch64-linux"
      "aarch64-darwin"
    ];

    forAllDevSystems = fn:
      nixpkgs.lib.genAttrs devSystems
      (system: fn { pkgs = import nixpkgs { inherit system; }; });
  in {
    nixosConfigurations.sdImage = nixpkgs.lib.nixosSystem {
      system = "aarch64-linux";
      modules = [
        self.nixosModules.sdImage
        self.nixosModules.stratum
      ];
    };

    nixosModules = rec {
      stratum = ./default.nix;
      sdImage = ./modules/sd-image;
      default = stratum;
    };

    packages = forAllDevSystems ( { pkgs }: {
      default = self.nixosConfigurations.sdImage.config.system.build.sdImage;
    });

    devShells = forAllDevSystems ( { pkgs }: {
      default = pkgs.mkShell {
        buildInputs = with pkgs; [
          just
        ];

        shellHook = ''
          cat <<EOF
          $(just -l |sed 's/^Available recipes:/The following `just` recipes are available:/')
          EOF
          user_shell=$(getent passwd "$(whoami)" |cut -d: -f 7)
          exec "$user_shell"
        '';
      };
    });
  };
}

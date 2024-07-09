{
  description = "";

  inputs = {
    nixos.url = "nixpkgs/23.11"; # for live media
    klokkijker.url = "github:koenw/klokkijker";
  };

  outputs = { self, nixpkgs, nixos, klokkijker }@inputs:
  let
    devSystems = [
      "x86_64-linux"
      "aarch64-linux"
      "aarch64-darwin"
    ];

    forAllDevSystems = fn:
      nixpkgs.lib.genAttrs devSystems
      (system: fn {
        pkgs = import nixpkgs { inherit system; };
      });
  in {
    nixosConfigurations.sdImage = nixpkgs.lib.nixosSystem {
      system = "aarch64-linux";
      modules = [
        self.nixosModules.sdImage
        self.nixosModules.stratum
      ];
    };

    nixosModules = rec {
      stratum = ( import ./default.nix { inherit klokkijker; } );
      default = stratum;
      sdImage = ./modules/sd-image;
    };

    packages = forAllDevSystems ( { pkgs }: {
      default = self.nixosConfigurations.sdImage.config.system.build.sdImage;
      mdDocs = pkgs.callPackage ./modules/docs.nix {};
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

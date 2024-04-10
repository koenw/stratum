{ lib, runCommand, nixosOptionsDoc, ... }:
let
  eval = lib.evalModules {
    modules = [
      ./options.nix
    ];
  };

  optionsDoc = nixosOptionsDoc {
    options = eval.options;
  };
in
  runCommand "options-doc.md" {} ''
    cat <<EOF - ${optionsDoc.optionsCommonMark} > $out
    # Stratum options


    EOF
  ''

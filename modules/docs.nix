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
    # The sed rewrites the 'Declared by' links to relative links
    cat <<EOF - ${optionsDoc.optionsCommonMark} | sed 's!\[/nix/store/[^/]\+/\([^]]\+\)](\([^)]\+\)![\1](../\1)!' > $out
    # Stratum options


    EOF
  ''

{ lib, runCommand, nixosOptionsDoc, ... }:
let
  eval = lib.evalModules {
    modules = [
      ./options.nix
    ];
  };

  optionsDoc = nixosOptionsDoc {
    inherit (eval) options;
  };
in
  runCommand "options-doc.md" {} ''
    cat ${optionsDoc.optionsCommonMark} >> $out
  ''

{ pkgs ? import <nixpkgs> {} }:
with pkgs;
with stdenv;
mkDerivation {
  name = "parse-example";
  buildInputs = [ elmPackages.elm pkgs.mongodb pkgs.nodejs ];
}

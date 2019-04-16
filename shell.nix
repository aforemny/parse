{ pkgs ? import <nixpkgs> {} }:
with pkgs;
with stdenv;
mkDerivation {
  name = "elm-parse";
  buildInputs = [
    elmPackages.elm
  ];
}

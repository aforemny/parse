{ pkgs ? import <nixpkgs> {} }:
with pkgs;
with stdenv;
mkDerivation {
  name = "live-queries";
  buildInputs = [
    pkgs.elmPackages.elm
    pkgs.mongodb
    pkgs.nodejs
  ];
}

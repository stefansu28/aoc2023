{
  system ? builtins.currentSystem
}:
let
  pkgs = import <nixpkgs> {};

  zig-overlay = pkgs.fetchFromGitHub {
    owner = "mitchellh";
    repo = "zig-overlay";
    rev = "2c9179e22a4759c7c88438a4a9eb0f5e3c00d3b0";
    sha256 = "sha256-EfM3pRvtb5TrvxURhtI1gEKb/mSXHJx3A/12HOWKOyI=";
  };

  # need version 0.12.0-dev.1710+2bffd8101
  zig = (import zig-overlay { inherit pkgs system; })."master-2023-11-24";
  # pkgconfig fixes the compiler options so the SDL headers get included correctly.
  buildInputs = [
      zig
  ];

in pkgs.stdenv.mkDerivation {
  name = "aoc2023";
  buildInputs = buildInputs;
}
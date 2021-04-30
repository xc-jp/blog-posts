{ pkgs ? import <nixpkgs> {} }:

pkgs.stdenv.mkDerivation {
  name = "xc-blog-posts";
  src = builtins.path { path = ./.; name = "blog-posts"; }; # https://nix.dev/anti-patterns/language.html#reproducability-referencing-top-level-directory-with
  nativeBuildInputs = [pkgs.pandoc];
  phases = "unpackPhase installPhase";
  unpackPhase = ''
    cp $src/*.md ./
  '';
  installPhase = ''
    mkdir -p $out
    for file in *.md; do
      pandoc $file --from markdown --to html --standalone --output "$out/''${file%%.md}.html"
    done
  '';
}


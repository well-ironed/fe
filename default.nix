{ pkgs ? import <nixpkgs> {} }:

with pkgs;

let
  erlang = beam.interpreters.erlang_28;
  elixir = beam.packages.erlang_28.elixir_1_18;
in

mkShell {
  buildInputs = [ erlang elixir ];
}

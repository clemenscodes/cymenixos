{
  pkgs,
  lib,
  ...
}: let
  fetchFile = name: hash:
    pkgs.fetchurl {
      inherit name hash;
      url = "https://huggingface.co/istupakov/parakeet-tdt-0.6b-v3-onnx/resolve/main/${name}";
    };
in
  pkgs.runCommand "parakeet-tdt-0.6b-v3" {} ''
    mkdir -p $out
    ${lib.concatMapStringsSep "\n" (file: "cp ${file} $out/${file.name}") [
      (fetchFile "encoder-model.onnx" "sha256-mKdLIbTMABfB5wMDGaSpb0qVBuUPBwjzpRbQKnfJa7E=")
      (fetchFile "encoder-model.onnx.data" "sha256-miLTcsUUVcNPE0BdolILrvtxJb0WmBOXVhQj7TLSTzY=")
      (fetchFile "decoder_joint-model.onnx" "sha256-6Xjd9miFJxgsEP3i60uDBoQhZImF7yP3qGvnMr6HBsE=")
      (fetchFile "vocab.txt" "sha256-1YVEZ56kvGrFY9H1Ret9R0vWz6Rn8KbiwdwcfTfjw10=")
      (fetchFile "config.json" "sha256-ZmkDx2uXmMrywhCv1PbNYLCKjb+YAOyNejvA0hSKxGY=")
    ]}
  ''

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
      (fetchFile "encoder-model.int8.onnx" "sha256-YTnS+n4bCGCXsnfHFJcl7bq4nMfHrmSyPHQb5AVa/wk=")
      (fetchFile "decoder_joint-model.int8.onnx" "sha256-7qdIPuPRowN12u3I7YPjlgyRsJiBISeg2Z0ciXdmenA=")
      (fetchFile "vocab.txt" "sha256-1YVEZ56kvGrFY9H1Ret9R0vWz6Rn8KbiwdwcfTfjw10=")
      (fetchFile "config.json" "sha256-ZmkDx2uXmMrywhCv1PbNYLCKjb+YAOyNejvA0hSKxGY=")
    ]}
  ''

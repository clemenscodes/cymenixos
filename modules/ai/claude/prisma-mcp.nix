{
  lib,
  stdenv,
  prisma,
  makeWrapper,
}:
stdenv.mkDerivation {
  pname = "prisma-mcp";
  inherit (prisma) version;

  dontUnpack = true;

  nativeBuildInputs = [makeWrapper];

  # The Prisma CLI exposes MCP functionality via `prisma mcp`
  installPhase = ''
    mkdir -p $out/bin
    makeWrapper ${prisma}/bin/prisma $out/bin/prisma-mcp \
      --add-flags "mcp"
  '';

  meta = {
    description = "MCP server for Prisma ORM — schema management, migrations, and database introspection";
    homepage = "https://www.prisma.io/docs/orm/tools/mcp";
    license = lib.licenses.asl20;
    mainProgram = "prisma-mcp";
  };
}

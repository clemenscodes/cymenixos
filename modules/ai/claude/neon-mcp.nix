{
  lib,
  buildNpmPackage,
  fetchFromGitHub,
  nodejs_22,
}:
buildNpmPackage {
  pname = "mcp-server-neon";
  version = "0.2.0";

  src = fetchFromGitHub {
    owner = "neondatabase";
    repo = "mcp-server-neon";
    rev = "9ab15af67fdb5b6903b3156518ae49ca13a33f6d";
    hash = "sha256-93AVp8G2gT4gjhktDBO7dTUN+fCl2jqrzQwPaN+R4RM=";
  };

  npmDepsHash = "sha256-zjhuCwMU3dsz0GI3komvOy2Vw6XzE7i0xTYIDclBuRk=";
  nodejs = nodejs_22;

  meta = {
    description = "MCP server for Neon serverless Postgres — manage databases and run SQL";
    homepage = "https://github.com/neondatabase/mcp-server-neon";
    license = lib.licenses.mit;
    mainProgram = "mcp-server-neon";
  };
}

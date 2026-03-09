{
  python3Packages,
  fetchFromGitHub,
}:
python3Packages.buildPythonApplication {
  pname = "mcp-server-time";
  version = "0.6.2";

  src = fetchFromGitHub {
    owner = "modelcontextprotocol";
    repo = "servers";
    rev = "a97aba19eb218bedd37ae19c27893ee6659f1555";
    hash = "sha256-aNqRSkiQqxYc3MqJE6d1HsJTNegAgtElmBQy0pzcH3g=";
  };

  sourceRoot = "source/src/time";

  pyproject = true;

  build-system = with python3Packages; [hatchling];

  dependencies = with python3Packages; [
    mcp
    pydantic
    tzdata
    tzlocal
  ];

  meta = {
    description = "MCP server providing time and timezone conversion tools for LLMs";
    homepage = "https://github.com/modelcontextprotocol/servers/tree/main/src/time";
    mainProgram = "mcp-server-time";
  };
}

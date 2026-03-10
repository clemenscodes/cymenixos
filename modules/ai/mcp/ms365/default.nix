{
  pkgs,
  lib,
  ...
}: {config, ...}: let
  cfg = config.modules.ai.mcp.ms365;
  ms365-mcp = pkgs.callPackage ./package.nix {};
  orgModeArgs = lib.optionals cfg.orgMode ["--org-mode"];
  presetArgs = lib.optionals (cfg.preset != null) ["--preset" cfg.preset];
  readOnlyArgs = lib.optionals cfg.readOnly ["--read-only"];
in {
  options.modules.ai.mcp.ms365 = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = ''
        Enable the Microsoft 365 MCP server (@softeria/ms-365-mcp-server).

        Provides 90+ tools across mail, calendar, Teams, OneDrive, SharePoint,
        Excel, OneNote, contacts, tasks, and organisational search.

        ## Authentication

        Authentication is handled via the Microsoft Identity Platform (Entra ID /
        Azure AD).  You must register an application in your tenant before the
        server can start.

        ### Step 1 — Register an app in Azure Portal

        1. Go to https://portal.azure.com → **Microsoft Entra ID** →
           **App registrations** → **New registration**.
        2. Name it (e.g. "ms365-mcp"), set *Supported account types* to
           **"Accounts in this organizational directory only"**, and leave the
           redirect URI blank for now.
        3. Note the **Application (client) ID** and **Directory (tenant) ID**
           from the Overview page.

        ### Step 2 — Create a client secret

        In the registered app: **Certificates & secrets** → **New client secret**.
        Note the secret *value* immediately (it is only shown once).

        ### Step 3 — Grant Microsoft Graph permissions

        In the registered app: **API permissions** → **Add a permission** →
        **Microsoft Graph** → **Delegated permissions**.  Add the scopes you need,
        for example:

        | Scope | Purpose |
        |---|---|
        | `Mail.ReadWrite` | Read and send email |
        | `Calendars.ReadWrite` | Read and manage calendar events |
        | `Chat.ReadWrite` | Read and send Teams chat messages |
        | `ChannelMessage.Read.All` | Read Teams channel messages |
        | `Files.ReadWrite.All` | OneDrive / SharePoint files |
        | `Sites.ReadWrite.All` | SharePoint sites |
        | `User.Read` | Basic profile (always needed) |
        | `User.ReadBasic.All` | Look up colleagues (org mode) |

        Then click **Grant admin consent** for your tenant (requires a Global
        Administrator or Privileged Role Administrator account).

        ### Step 4 — Export credentials to your shell

        The MCP server reads credentials from the following environment variables,
        which are expected to be set in your shell session before launching Claude:

        ```sh
        export MS365_MCP_CLIENT_ID="<Application (client) ID>"
        export MS365_MCP_CLIENT_SECRET="<client secret value>"
        export MS365_MCP_TENANT_ID="<Directory (tenant) ID>"
        ```

        Add these to `~/.zshrc` (or a secrets file sourced by it — consider using
        SOPS or `pass` to avoid storing the secret in plaintext).

        ### First-time device-code login

        The server uses delegated (user) auth and must complete an OAuth consent
        flow once per account.  On the first run it will print a device-code URL to
        stderr.  Open the URL in a browser, sign in with your M365 work account,
        and approve the requested permissions.  The token is then cached in
        `~/.ms-365-mcp-server/` and silently refreshed on subsequent runs.

        You can also trigger this manually (useful for headless systems):

        ```sh
        ms-365-mcp-server --login
        ```
      '';
    };

    readOnly = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = ''
        Start the server in read-only mode (passes `--read-only`).

        Disables all write/send/modify operations at the application level,
        regardless of what OAuth scopes were granted.  This is the safest
        default — enable write access explicitly only when you need it.
      '';
    };

    orgMode = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        Enable organisation / work mode (passes `--org-mode` to the server).

        Required for any tool that touches Teams, SharePoint, shared mailboxes,
        Planner, or the user directory.  Widens the OAuth consent scope request
        at first login; if you already have a cached token you may need to
        re-authenticate after enabling this (`ms-365-mcp-server --login`).

        Also automatically enabled when `preset` includes "work" or "users".
      '';
    };

    preset = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      example = "work";
      description = ''
        Restrict the server to a named subset of tools (passes `--preset <value>`).
        Use a comma-separated list to combine presets.

        Available presets:

        | Preset | Tools included |
        |---|---|
        | `mail` | Email (read, send, manage folders, attachments) |
        | `calendar` | Calendar and event management |
        | `files` | OneDrive file / folder operations |
        | `personal` | mail + calendar + files + contacts + tasks + notes + search |
        | `work` | Teams, SharePoint, shared mailboxes, Planner, search (requires orgMode) |
        | `excel` | Excel spreadsheet operations |
        | `contacts` | Outlook contacts |
        | `tasks` | To Do and Planner |
        | `onenote` | OneNote notebooks |
        | `search` | Microsoft Search |
        | `users` | User directory lookup (requires orgMode) |
        | `all` | Everything (default when preset is null) |

        Example for a work-only setup:
        ```nix
        modules.ai.mcp.ms365.preset = "work";
        modules.ai.mcp.ms365.orgMode = true;
        ```

        Example combining personal and work:
        ```nix
        modules.ai.mcp.ms365.preset = "personal,work";
        modules.ai.mcp.ms365.orgMode = true;
        ```
      '';
    };
  };

  config = lib.mkIf (config.modules.ai.enable && config.modules.ai.mcp.enable && cfg.enable) {
    modules.ai.mcp.servers.ms365 = {
      command = "${ms365-mcp}/bin/ms-365-mcp-server";
      args = readOnlyArgs ++ orgModeArgs ++ presetArgs;
      env = {
        MS365_MCP_CLIENT_ID = ''''${MS365_MCP_CLIENT_ID}'';
        MS365_MCP_CLIENT_SECRET = ''''${MS365_MCP_CLIENT_SECRET}'';
        MS365_MCP_TENANT_ID = ''''${MS365_MCP_TENANT_ID}'';
      };
    };
  };
}

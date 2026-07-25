# GitEasy MCP server — stdio entry point for MCP clients and registry checks.
#
# GitEasy MCP is a hosted server (streamable HTTP at giteasy-mcp.azurewebsites.net/mcp).
# This image bridges stdio to that endpoint via mcp-remote, so anything that
# speaks MCP over stdio (Glama checks, Claude Desktop, inspectors) can use it
# without needing HTTP transport support.
#
# Build:  docker build -t giteasy-mcp .
# Run:    docker run -i --rm giteasy-mcp
# Check:  send a JSON-RPC initialize request on stdin; the server answers as
#         GitEasy.MCP and tools/list returns the 22 git tools.

FROM node:22-alpine

RUN npm install -g mcp-remote@0.1.38

ENTRYPOINT ["mcp-remote", "https://giteasy-mcp.azurewebsites.net/mcp", "--transport", "http-only"]

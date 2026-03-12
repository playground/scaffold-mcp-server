# MCP Server Scaffolding Script

A bash script to quickly scaffold new MCP (Model Context Protocol) server projects based on the `memgraphdb-mcp-server` template.

## Features

- 🚀 **Quick Setup**: Create a complete MCP server project structure in seconds
- 📁 **Complete Structure**: Includes all necessary directories and files
- 🔧 **Ready to Use**: Pre-configured with TypeScript, Express, and MCP SDK
- 🐳 **Docker Ready**: Includes Dockerfile and .dockerignore
- 📝 **Documentation**: Auto-generates README and getting started guide
- ✅ **Best Practices**: Follows MCP server patterns and conventions

## Prerequisites

- Bash shell (macOS, Linux, or WSL on Windows)
- Node.js 18+ (for running the generated project)

## Installation

### Option 1: Quick Install with curl (Recommended)

Download and run the script directly:

```bash
curl -fsSL https://raw.githubusercontent.com/YOUR_USERNAME/YOUR_REPO/main/scaffold-mcp-server.sh | bash -s -- my-mcp-server
```

Replace `my-mcp-server` with your desired server name.

**Or download first, then run:**

```bash
# Download the script
curl -fsSL https://raw.githubusercontent.com/YOUR_USERNAME/YOUR_REPO/main/scaffold-mcp-server.sh -o scaffold-mcp-server.sh

# Make it executable
chmod +x scaffold-mcp-server.sh

# Run it
./scaffold-mcp-server.sh my-mcp-server
```

### Option 2: Local Installation

If you already have the script locally:

```bash
chmod +x scaffold-mcp-server.sh
./scaffold-mcp-server.sh <server-name>
```

## Usage

### Basic Usage

```bash
./scaffold-mcp-server.sh <server-name>
```

### Example

```bash
./scaffold-mcp-server.sh my-mcp-server
```

This will create a new directory `my-mcp-server/` with the complete project structure.

### One-Line Quick Start

Create and start a new MCP server in one command:

```bash
curl -fsSL https://raw.githubusercontent.com/YOUR_USERNAME/YOUR_REPO/main/scaffold-mcp-server.sh | bash -s -- my-mcp-server && cd my-mcp-server && npm install && cp .env.example .env && npm run dev
```

### Server Name Requirements

- Must contain only lowercase letters, numbers, and hyphens
- Examples: `my-mcp-server`, `api-connector-mcp`, `database-query-server`

## Generated Project Structure

```
your-server-name/
├── src/
│   ├── tools/              # MCP tools (functions callable by AI)
│   │   └── exampleTool.ts  # Example tool implementation
│   ├── services/           # Business logic and utilities
│   │   └── common.ts       # Common utility functions
│   ├── models/             # TypeScript interfaces and types
│   │   └── model.ts        # Data models and session types
│   ├── prompts/            # MCP prompts (pre-defined interactions)
│   │   └── example-prompts.ts
│   ├── scripts/            # Utility scripts
│   ├── mcp-server.ts       # MCP server configuration
│   └── server.ts           # HTTP server entry point
├── docs/
│   └── GETTING_STARTED.md  # Quick start guide
├── package.json            # Node.js dependencies and scripts
├── tsconfig.json           # TypeScript configuration
├── Dockerfile              # Docker container configuration
├── .dockerignore           # Docker ignore patterns
├── .env.example            # Environment variables template
├── .gitignore              # Git ignore patterns
└── README.md               # Project documentation
```

## Quick Start After Scaffolding

1. **Navigate to your project**:
   ```bash
   cd your-server-name
   ```

2. **Install dependencies**:
   ```bash
   npm install
   ```

3. **Configure environment**:
   ```bash
   cp .env.example .env
   # Edit .env with your configuration
   ```

4. **Run in development mode**:
   ```bash
   npm run dev
   ```

5. **Test the server**:
   ```bash
   curl http://localhost:3000/mcp/health
   ```

## Available NPM Scripts

The generated project includes these scripts:

- `npm run dev` - Run in development mode with hot reload
- `npm run build` - Build TypeScript to JavaScript
- `npm start` - Build and run in production mode
- `npm run dev:port` - Run on custom port: `npm run dev:port --port=3001`
- `npm run inspector` - Run MCP inspector for debugging
- `npm run build:docker:arm64` - Build Docker image for ARM64 (Apple Silicon)
- `npm run build:docker:amd64` - Build Docker image for AMD64 (Intel/AMD)

## Customizing Your Server

### 1. Add Your Tools

Create new tool files in `src/tools/`:

```typescript
// src/tools/myTool.ts
import { McpServer } from '@modelcontextprotocol/sdk/server/mcp.js';
import { z } from 'zod';

export function registerMyTool(server: McpServer) {
  server.tool(
    'my-tool',
    'Description of what this tool does',
    {
      param1: z.string().describe('Parameter description')
    },
    async (params: any) => {
      // Your tool logic here
      return {
        content: [{ type: 'text', text: 'Result' }]
      };
    }
  );
}
```

Then register it in `src/mcp-server.ts`:

```typescript
import { registerMyTool } from './tools/myTool';
// ...
registerMyTool(server);
```

### 2. Add Your Prompts

Create prompt files in `src/prompts/`:

```typescript
// src/prompts/my-prompts.ts
import { McpServer } from '@modelcontextprotocol/sdk/server/mcp.js';

export function registerMyPrompts(server: McpServer) {
  server.prompt(
    'my-prompt',
    'Description of this prompt',
    async (args: any) => {
      return {
        messages: [
          {
            role: 'user',
            content: {
              type: 'text',
              text: 'Your prompt content'
            }
          }
        ]
      };
    }
  );
}
```

### 3. Add Your Services

Create service files in `src/services/` for business logic, API clients, database connections, etc.

### 4. Update Configuration

- Edit `.env` for environment-specific settings
- Update `package.json` with your project details
- Customize `README.md` with your documentation

## Docker Deployment

### Build Docker Image

```bash
# For ARM64 (Apple Silicon)
npm run build:docker:arm64

# For AMD64 (Intel/AMD)
npm run build:docker:amd64
```

### Run Docker Container

```bash
docker run -p 3000:8080 --env-file .env your-image-name
```

## MCP Server Architecture

The generated server follows the MCP (Model Context Protocol) specification:

- **Stateful Sessions**: Each client connection maintains its own session
- **Streamable HTTP**: Uses HTTP with Server-Sent Events (SSE) for bidirectional communication
- **Tools**: Functions that AI assistants can call to perform actions
- **Prompts**: Pre-defined interaction patterns for common tasks
- **Resources**: Data sources that can be queried

## Environment Variables

The `.env.example` file includes:

```env
PORT=3000                    # Server port
# Add your service-specific variables here
```

## Health Check

The server includes a health check endpoint:

```bash
curl http://localhost:3000/mcp/health
# Response: {"status":"healthy"}
```

## Troubleshooting

### Script Errors

- **Permission denied**: Run `chmod +x scaffold-mcp-server.sh`
- **Directory exists**: Choose a different server name or remove the existing directory
- **Invalid name**: Use only lowercase letters, numbers, and hyphens

### Generated Project Issues

- **Module not found**: Run `npm install`
- **TypeScript errors**: Check `tsconfig.json` configuration
- **Port in use**: Change PORT in `.env` or use `npm run dev:port --port=3001`

## Examples

### Create a Database MCP Server

```bash
./scaffold-mcp-server.sh postgres-mcp-server
cd postgres-mcp-server
npm install
# Add pg dependency
npm install pg @types/pg
# Implement your database tools
```

### Create an API Integration Server

```bash
./scaffold-mcp-server.sh github-api-mcp-server
cd github-api-mcp-server
npm install
# Add axios dependency
npm install axios
# Implement your API tools
```

### Create a File System Server

```bash
./scaffold-mcp-server.sh filesystem-mcp-server
cd filesystem-mcp-server
npm install
# Implement file system tools
```

## Template Source

This scaffolding script is based on the `memgraphdb-mcp-server` template, which includes:

- Express HTTP server with MCP protocol support
- Session management for stateful connections
- TypeScript configuration
- Docker containerization
- Logging with log4js
- Input validation with Zod

## Contributing

To improve the scaffolding script:

1. Edit `scaffold-mcp-server.sh`
2. Test with: `./scaffold-mcp-server.sh test-server`
3. Verify the generated project works
4. Clean up: `rm -rf test-server`

## License

ISC

## Made with Bob

This scaffolding script was created to streamline MCP server development and follows best practices from the Model Context Protocol specification.
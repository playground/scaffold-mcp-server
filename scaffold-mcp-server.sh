#!/bin/bash

# scaffold-mcp-server.sh
# Script to scaffold a new MCP server project based on the memgraphdb-mcp-server template
# Usage: ./scaffold-mcp-server.sh <server-name>
# Example: ./scaffold-mcp-server.sh lag-mcp-server

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

# Check if server name is provided
if [ -z "$1" ]; then
    print_error "Error: Server name is required"
    echo "Usage: $0 <server-name>"
    echo "Example: $0 lag-mcp-server"
    exit 1
fi

SERVER_NAME="$1"
SERVER_DIR="$SERVER_NAME"

# Validate server name format
if [[ ! "$SERVER_NAME" =~ ^[a-z0-9-]+$ ]]; then
    print_error "Error: Server name must contain only lowercase letters, numbers, and hyphens"
    exit 1
fi

# Check if directory already exists
if [ -d "$SERVER_DIR" ]; then
    print_error "Error: Directory '$SERVER_DIR' already exists"
    exit 1
fi

print_info "Creating MCP server: $SERVER_NAME"
echo ""

# Create directory structure
print_info "Creating directory structure..."
mkdir -p "$SERVER_DIR"
mkdir -p "$SERVER_DIR/src/tools"
mkdir -p "$SERVER_DIR/src/services"
mkdir -p "$SERVER_DIR/src/models"
mkdir -p "$SERVER_DIR/src/prompts"
mkdir -p "$SERVER_DIR/src/scripts"
mkdir -p "$SERVER_DIR/docs"
print_success "Directory structure created"

# Create package.json
print_info "Creating package.json..."
cat > "$SERVER_DIR/package.json" << EOF
{
  "name": "$SERVER_NAME",
  "version": "1.0.0",
  "description": "MCP Server for $SERVER_NAME",
  "main": "dist/server.js",
  "scripts": {
    "build": "tsc && node -e \\"require('fs').chmodSync('dist/server.js', '755')\\"",
    "start": "npm run build && node dist/server.js",
    "dev": "nodemon --watch 'src/**/*.ts' --exec ts-node src/server.ts",
    "build:docker:arm64": "docker buildx build --platform=linux/arm64 -t playbox21/\${npm_package_name}_arm64:\$npm_package_version --load .",
    "build:docker:amd64": "docker buildx build --platform=linux/amd64 -t playbox21/\${npm_package_name}_amd64:\$npm_package_version --load .",
    "dev:port": "nodemon --watch 'src/**/*.ts' --exec PORT=\$npm_config_port ts-node src/server.ts",
    "inspector": "npx @modelcontextprotocol/inspector dist/server.js",
    "test": "echo \\"Error: no test specified\\" && exit 1"
  },
  "keywords": [
    "mcp",
    "$SERVER_NAME"
  ],
  "author": "",
  "license": "ISC",
  "type": "commonjs",
  "dependencies": {
    "@modelcontextprotocol/sdk": "^1.25.2",
    "cors": "^2.8.5",
    "dotenv": "^17.2.3",
    "express": "^5.2.1",
    "log4js": "^6.9.1",
    "zod": "^4.3.5"
  },
  "devDependencies": {
    "@types/cors": "^2.8.19",
    "@types/express": "^5.0.6",
    "@types/node": "^25.0.8",
    "nodemon": "^3.1.11",
    "ts-node": "^10.9.2",
    "typescript": "^5.9.3"
  }
}
EOF
print_success "package.json created"

# Create tsconfig.json
print_info "Creating tsconfig.json..."
cat > "$SERVER_DIR/tsconfig.json" << 'EOF'
{
  "compilerOptions": {
    "target": "ES2022",
    "module": "commonjs",
    "lib": ["ES2022"],
    "outDir": "./dist",
    "rootDir": "./src",
    "strict": true,
    "esModuleInterop": true,
    "skipLibCheck": true,
    "forceConsistentCasingInFileNames": true,
    "resolveJsonModule": true,
    "moduleResolution": "node",
    "declaration": true,
    "declarationMap": true,
    "sourceMap": true,
    "types": ["node"]
  },
  "include": ["src/**/*"],
  "exclude": ["node_modules", "dist"]
}
EOF
print_success "tsconfig.json created"

# Create .gitignore
print_info "Creating .gitignore..."
cat > "$SERVER_DIR/.gitignore" << 'EOF'
# Dependency directories
node_modules/
npm-debug.log
yarn-debug.log
yarn-error.log

# Build output
dist/
build/

# Environment variables
.env

# IDE files
.idea/
.vscode/
*.swp
*.swo

# OS files
.DS_Store
Thumbs.db

# Logs
logs
*.log
npm-debug.log*
yarn-debug.log*
yarn-error.log*
EOF
print_success ".gitignore created"

# Create .dockerignore
print_info "Creating .dockerignore..."
cat > "$SERVER_DIR/.dockerignore" << 'EOF'
node_modules
npm-debug.log
.git
.gitignore
README.md
.env*
.nyc_output
coverage
.eslintrc.js
.prettierrc
*.md
.DS_Store
Dockerfile*
docker-compose*
EOF
print_success ".dockerignore created"

# Create .env.example
print_info "Creating .env.example..."
cat > "$SERVER_DIR/.env.example" << 'EOF'
# MCP Server Environment Variables

# ============================================================================
# Server Settings
# ============================================================================
PORT=3000

# ============================================================================
# Add your service-specific configuration here
# ============================================================================
# Example:
# API_KEY=your_api_key_here
# API_URL=https://api.example.com
EOF
print_success ".env.example created"

# Create Dockerfile
print_info "Creating Dockerfile..."
cat > "$SERVER_DIR/Dockerfile" << 'EOF'
FROM node:22-slim AS builder

WORKDIR /app

# Copy package files first for better caching
COPY package*.json ./

# Install all dependencies (including devDependencies for build)
RUN npm ci && npm cache clean --force

# Copy source and build
COPY . .
RUN npm run build

# Remove devDependencies after build
RUN npm prune --production

# ---- Final runtime stage ----
FROM node:22-slim AS runtime

# Create non-root user for security
RUN groupadd -g 1001 appuser && useradd -r -u 1001 -g appuser appuser

WORKDIR /app

# Copy built application and dependencies from builder stage
COPY --from=builder --chown=appuser:appuser /app/dist ./dist
COPY --from=builder --chown=appuser:appuser /app/node_modules ./node_modules
COPY --from=builder --chown=appuser:appuser /app/package*.json ./

# Switch to non-root user
USER appuser

# IBM Code Engine uses PORT environment variable
ENV PORT=8080
EXPOSE $PORT

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD node -e "require('http').get('http://localhost:'+process.env.PORT+'/mcp/health', (res) => process.exit(res.statusCode === 200 ? 0 : 1)).on('error', () => process.exit(1))"

CMD ["node", "dist/server.js"]
EOF
print_success "Dockerfile created"

# Create src/models/model.ts
print_info "Creating src/models/model.ts..."
cat > "$SERVER_DIR/src/models/model.ts" << 'EOF'
import { McpServer } from '@modelcontextprotocol/sdk/server/mcp.js';
import { StreamableHTTPServerTransport } from '@modelcontextprotocol/sdk/server/streamableHttp.js';
import { IncomingHttpHeaders } from 'http';

/**
 * Session entry for managing MCP server sessions
 */
export interface SessionEntry {
  server: McpServer;
  transport: StreamableHTTPServerTransport;
  latestHeaders?: IncomingHttpHeaders;
}

// Add your custom models here
// Example:
// export interface YourModel {
//   id: string;
//   name: string;
//   // ... other fields
// }

// Made with Bob
EOF
print_success "src/models/model.ts created"

# Create src/services/common.ts
print_info "Creating src/services/common.ts..."
cat > "$SERVER_DIR/src/services/common.ts" << 'EOF'
/**
 * common.ts
 * 
 * Common utility functions for services
 */

import { IncomingHttpHeaders } from 'http';

/**
 * Extract headers from MCP context
 * This is useful for getting request-specific information
 */
export function getHeadersFromContext(context: any): IncomingHttpHeaders {
  if (context && context.meta && context.meta.headers) {
    return context.meta.headers as IncomingHttpHeaders;
  }
  return {};
}

/**
 * Format bytes to human-readable format
 */
export function formatBytes(bytes: number): string {
  if (bytes === 0) return '0 Bytes';
  
  const k = 1024;
  const sizes = ['Bytes', 'KB', 'MB', 'GB', 'TB'];
  const i = Math.floor(Math.log(bytes) / Math.log(k));
  
  return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i];
}

/**
 * Sleep for a specified number of milliseconds
 */
export function sleep(ms: number): Promise<void> {
  return new Promise(resolve => setTimeout(resolve, ms));
}

// Made with Bob
EOF
print_success "src/services/common.ts created"

# Create src/tools/exampleTool.ts
print_info "Creating src/tools/exampleTool.ts..."
cat > "$SERVER_DIR/src/tools/exampleTool.ts" << 'EOF'
/**
 * exampleTool.ts
 *
 * Example tool implementation
 * Replace this with your actual tool implementation
 */

import { McpServer } from '@modelcontextprotocol/sdk/server/mcp.js';
import { z } from 'zod';

export function registerExampleTool(server: McpServer) {
  const toolName = 'example-tool';
  const toolDescription = `
    Example tool that demonstrates the basic structure.
    
    Replace this with your actual tool description.
  `;
  
  const toolSchema = {
    message: z.string().describe('A message to process')
  };
  
  const toolCallback = async (params: any): Promise<any> => {
    try {
      const { message } = params;
      
      // Your tool logic here
      return {
        content: [
          {
            type: 'text',
            text: `Processed message: ${message}`
          }
        ]
      };
    } catch (error: any) {
      return {
        content: [
          {
            type: 'text',
            text: `Error: ${error.message}`
          }
        ],
        isError: true
      };
    }
  };
  
  server.tool(toolName, toolDescription, toolSchema, toolCallback);
}

// Made with Bob
EOF
print_success "src/tools/exampleTool.ts created"

# Create src/prompts/example-prompts.ts
print_info "Creating src/prompts/example-prompts.ts..."
cat > "$SERVER_DIR/src/prompts/example-prompts.ts" << 'EOF'
/**
 * example-prompts.ts
 *
 * Example prompts for the MCP server
 * Replace with your actual prompts
 */

import { McpServer } from '@modelcontextprotocol/sdk/server/mcp.js';

export function registerExamplePrompts(server: McpServer) {
  
  server.prompt(
    'example-prompt',
    'Example prompt that demonstrates the basic structure',
    async (args: any) => {
      return {
        messages: [
          {
            role: 'user',
            content: {
              type: 'text',
              text: 'This is an example prompt. Replace with your actual prompt content.'
            }
          }
        ]
      };
    }
  );
}

// Made with Bob
EOF
print_success "src/prompts/example-prompts.ts created"

# Create src/mcp-server.ts
print_info "Creating src/mcp-server.ts..."
SERVER_NAME_UPPER=$(echo "$SERVER_NAME" | tr '[:lower:]' '[:upper:]' | tr '-' '_')
cat > "$SERVER_DIR/src/mcp-server.ts" << EOF
/**
 * mcp-server.ts
 * 
 * $SERVER_NAME MCP Server - Factory to create and configure MCP server instances
 */

import { IncomingHttpHeaders } from 'http';
import { McpServer } from '@modelcontextprotocol/sdk/server/mcp.js';
import { registerExampleTool } from './tools/exampleTool';
import { registerExamplePrompts } from './prompts/example-prompts';

/**
 * Factory to create and configure a new McpServer
 *
 * @param initialHeaders - HTTP headers from the initial request
 * @returns Configured McpServer instance
 */
export function createMcpServer(initialHeaders: IncomingHttpHeaders): McpServer {
  
  /**
   * ============================================================================
   * MCP SERVER INSTRUCTIONS FOR AI ASSISTANTS
   * ============================================================================
   *
   * You are an assistant with access to the $SERVER_NAME MCP server.
   *
   * USE THIS SERVER FOR:
   * - [Add your use cases here]
   *
   * KEYWORDS THAT INDICATE THIS SERVER:
   * "[Add relevant keywords here]"
   *
   * CAPABILITIES:
   * - [List your tools and their purposes]
   *
   * IMPORTANT GUIDELINES:
   * - [Add any important guidelines for using this server]
   *
   * Always provide clear and actionable insights from the data.
   * ============================================================================
   */
  
  // Create a new MCP server with proper configuration
  const server = new McpServer(
    {
      name: '$SERVER_NAME',
      version: '1.0.0'
    },
    {
      capabilities: {
        tools:     { listChanged: true },
        resources: { listChanged: true },
        prompts:   { listChanged: true }
      }
    }
  );
  
  // Register tools
  registerExampleTool(server);
  
  // Register prompts
  registerExamplePrompts(server);
  
  // Add status resource
  server.resource(
    'server-status',
    'status://server',
    async (uri: URL) => {
      const statusText = \`$SERVER_NAME Status:

Server Version: 1.0.0
Timestamp: \${new Date().toISOString()}

Status: Operational\`;
      
      return {
        contents: [
          {
            uri: uri.href,
            text: statusText
          }
        ]
      };
    }
  );
  
  return server;
}

// Made with Bob
EOF
print_success "src/mcp-server.ts created"

# Create src/server.ts
print_info "Creating src/server.ts..."
cat > "$SERVER_DIR/src/server.ts" << EOF
/**
 * server.ts
 *
 * $SERVER_NAME MCP Server (Streamable HTTP, Stateful)
 */

import log4js from 'log4js';
import express from "express";
import { randomUUID } from 'crypto';
import { StreamableHTTPServerTransport } from "@modelcontextprotocol/sdk/server/streamableHttp.js";
import { isInitializeRequest } from '@modelcontextprotocol/sdk/types.js';
import { Request, Response } from 'express';
import { SessionEntry } from './models/model';
import { createMcpServer } from './mcp-server';
import * as dotenv from 'dotenv';

// Load environment variables from .env file
dotenv.config();

/**
 * In-memory session store:
 *   sessions[sessionId] = {
 *     server:   McpServer instance for this session,
 *     transport: StreamableHTTPServerTransport bound to this session
 *   }
 */
const sessions: Record<string, SessionEntry> = {};

const l = log4js.getLogger();

const MCP_PATH = '/mcp';

const app = express();
app.use(express.json());

app.use((req, res, next) => {
    l.debug(\`> \${req.method} \${req.originalUrl}\`);
    l.debug(req.body);
    return next();
});

// Handle GET requests for server-to-client notifications via SSE
app.get(MCP_PATH, (req, res) => {
    res.status(405).set('Allow', 'POST').send('Method Not Allowed');
});

// Handle DELETE requests for session termination
app.delete(MCP_PATH, (req, res) => {
    res.status(405).set('Allow', 'POST').send('Method Not Allowed');
});

/**
 * Handler for POST /mcp:
 *   1. If "mcp-session-id" header exists and matches a stored session, reuse that session.
 *   2. If no "mcp-session-id" and request is initialize, create new session and handshake.
 *   3. Otherwise, return a 400 error.
 */
app.post(MCP_PATH, async (req, res) => {
  const sessionIdHeader = req.headers['mcp-session-id'];
  let sessionEntry = null;

  // Case 1: Existing session found
  const sessionId =
    typeof sessionIdHeader === 'string'
      ? sessionIdHeader
      : Array.isArray(sessionIdHeader)
      ? sessionIdHeader[0]
      : undefined;

  if (sessionId && sessions[sessionId]) {
    sessionEntry = sessions[sessionId];

  // Case 2: Initialization request → create new transport + server
  } else if (!sessionIdHeader && isInitializeRequest(req.body)) {
    const newSessionId = randomUUID();
    const initialHeaders = {...req.headers};

    // Create a new transport for this session
    const transport = new StreamableHTTPServerTransport({
      sessionIdGenerator: () => newSessionId,
      onsessioninitialized: (sid: string) => {
        // Store the Transport and Server instance once session is initialized
        sessions[sid] = { server, transport, latestHeaders: initialHeaders};
      }
    });

    // Create and configure the new McpServer
    const server = createMcpServer(initialHeaders);
    
    // When this transport closes, clean up the session entry
    transport.onclose = () => {
      if (transport.sessionId && sessions[transport.sessionId]) {
        delete sessions[transport.sessionId];
      }
    };
    
    // Type assertion to satisfy exactOptionalPropertyTypes requirement
    // The transport has onclose defined above, so this is safe
    await server.connect(transport as any);

    // After \`onsessioninitialized\` fires, \`sessions[newSessionId]\` is set.
    // But we can also assign it here for immediate access.
    sessions[newSessionId] = { server, transport };
    sessionEntry = sessions[newSessionId];

  } else {
    // Neither a valid session nor an initialize request → return error
    res.status(400).json({
      jsonrpc: '2.0',
      error: { code: -32000, message: 'Bad Request: No valid session ID provided' },
      id: null
    });
    return;
  }

  // Forward the request to the transport of the retrieved/created session
  await sessionEntry.transport.handleRequest(req, res, req.body);
});

/**
 * Handler for GET/DELETE /mcp:
 *   Used for server-to-client notifications (SSE) and session termination.
 */
async function handleSessionRequest(req: Request, res: Response) {
  const sessionIdHeader = req.headers['mcp-session-id'];
  const sessionId =
    typeof sessionIdHeader === 'string'
      ? sessionIdHeader
      : Array.isArray(sessionIdHeader)
      ? sessionIdHeader[0]
      : undefined;
  if (!sessionId || !sessions[sessionId]) {
    res.statusCode = 400;
    res.send('Invalid or missing session ID');
    return;
  }
  const { transport } = sessions[sessionId];
  await transport.handleRequest(req, res);
}

app.get('/mcp', handleSessionRequest);
app.delete('/mcp', handleSessionRequest);

// Health check endpoint
app.get('/mcp/health', (req, res) => {
  res.status(200).json({ status: 'healthy' });
});

// Start the server using PORT from environment variables
const PORT = process.env.PORT || 3000;
const server = app.listen(PORT, () => {
  console.log(\`$SERVER_NAME MCP Server listening on port: \${PORT}\`);
});

// Prevent the Node.js process from exiting
process.stdin.resume();

// Made with Bob
EOF
print_success "src/server.ts created"

# Create README.md
print_info "Creating README.md..."
cat > "$SERVER_DIR/README.md" << EOF
# $SERVER_NAME

MCP (Model Context Protocol) server for $SERVER_NAME.

## Features

- [Add your features here]

## Installation

\`\`\`bash
npm install
\`\`\`

## Configuration

Create a \`.env\` file based on \`.env.example\`:

\`\`\`bash
cp .env.example .env
\`\`\`

Edit the \`.env\` file with your configuration:

\`\`\`env
PORT=3000
# Add your configuration variables here
\`\`\`

## Usage

### Development

\`\`\`bash
npm run dev
\`\`\`

### Production

\`\`\`bash
npm run build
npm start
\`\`\`

### Health Check

\`\`\`bash
curl http://localhost:3000/mcp/health
\`\`\`

## Tools

### example-tool

[Describe your tool here]

## Prompts

### example-prompt

[Describe your prompt here]

## Resources

- **server-status**: Check server status

## Development

### Build

\`\`\`bash
npm run build
\`\`\`

### Run Tests

\`\`\`bash
npm test
\`\`\`

### Docker Build

\`\`\`bash
# For ARM64 (Apple Silicon)
npm run build:docker:arm64

# For AMD64 (Intel/AMD)
npm run build:docker:amd64
\`\`\`

## License

ISC

## Made with Bob
EOF
print_success "README.md created"

# Create docs/GETTING_STARTED.md
print_info "Creating docs/GETTING_STARTED.md..."
cat > "$SERVER_DIR/docs/GETTING_STARTED.md" << EOF
# Getting Started with $SERVER_NAME

## Prerequisites

- Node.js 18+ installed
- npm or yarn package manager

## Quick Start

1. **Install dependencies**

   \`\`\`bash
   npm install
   \`\`\`

2. **Configure environment**

   \`\`\`bash
   cp .env.example .env
   \`\`\`

   Edit \`.env\` with your configuration.

3. **Run in development mode**

   \`\`\`bash
   npm run dev
   \`\`\`

4. **Test the server**

   \`\`\`bash
   curl http://localhost:3000/mcp/health
   \`\`\`

## Next Steps

- Add your tools in \`src/tools/\`
- Add your prompts in \`src/prompts/\`
- Update \`src/mcp-server.ts\` to register your tools and prompts
- Update the README.md with your documentation

## Made with Bob
EOF
print_success "docs/GETTING_STARTED.md created"

# Summary
echo ""
print_success "✨ MCP server '$SERVER_NAME' scaffolded successfully!"
echo ""
print_info "Next steps:"
echo "  1. cd $SERVER_DIR"
echo "  2. npm install"
echo "  3. cp .env.example .env"
echo "  4. Edit .env with your configuration"
echo "  5. npm run dev"
echo ""
print_info "Project structure:"
echo "  $SERVER_DIR/"
echo "  ├── src/"
echo "  │   ├── tools/          # Add your MCP tools here"
echo "  │   ├── services/       # Add your service logic here"
echo "  │   ├── models/         # Add your data models here"
echo "  │   ├── prompts/        # Add your MCP prompts here"
echo "  │   ├── scripts/        # Add utility scripts here"
echo "  │   ├── mcp-server.ts   # MCP server configuration"
echo "  │   └── server.ts       # HTTP server entry point"
echo "  ├── docs/               # Documentation"
echo "  ├── package.json"
echo "  ├── tsconfig.json"
echo "  ├── Dockerfile"
echo "  ├── .env.example"
echo "  ├── .gitignore"
echo "  └── README.md"
echo ""
print_success "Happy coding! 🚀"
echo ""
print_info "Made with Bob"
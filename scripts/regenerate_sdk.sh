#!/bin/bash

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

echo -e "${BLUE}🔄 Starting GPCore SDK regeneration...${NC}"

# Change to project directory
cd "$PROJECT_DIR"

# Clean up existing generated code (but keep our custom files)
echo -e "${YELLOW}🧹 Cleaning up existing generated code...${NC}"
rm -rf src/gpcore_sdk/gpcore src/gpcore_sdk/buf src/gpcore_sdk/google

# Create/clean .tmp directory
echo -e "${YELLOW}📁 Setting up temporary directory...${NC}"
rm -rf .tmp
mkdir -p .tmp
cd .tmp

# Download and install buf CLI if not present
if ! command -v buf &> /dev/null && [ ! -f "./buf" ]; then
    echo -e "${BLUE}⬇️  Downloading buf CLI...${NC}"
    curl -sSL https://github.com/bufbuild/buf/releases/latest/download/buf-Linux-x86_64.tar.gz | tar -xzf -
    mv buf/bin/buf ./buf
    chmod +x ./buf
    rm -rf buf/
fi

# Use local buf if global not available
if ! command -v buf &> /dev/null; then
    BUF_CMD="./buf"
else
    BUF_CMD="buf"
fi

# Export protobuf files from buf.build
echo -e "${BLUE}📥 Exporting protobuf files from buf.build/gportal/gpcore...${NC}"
$BUF_CMD export buf.build/gportal/gpcore --output ./proto_files

# Verify proto files were downloaded
if [ ! -d "./proto_files/gpcore" ]; then
    echo -e "${RED}❌ Failed to download protobuf files${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Found protobuf files:${NC}"
find ./proto_files/gpcore -name "*.proto" | head -5 | sed 's/^/  - /'
echo "  ..."

# Go back to project directory for generation
cd "$PROJECT_DIR"

echo -e "${BLUE}🔧 Generating Python code from protobuf files...${NC}"

# Install dependencies if not already installed
echo -e "${YELLOW}📦 Installing dependencies...${NC}"
poetry install --quiet

# Generate protobuf files in stages to handle dependencies
echo -e "${BLUE}  Generating core types and options...${NC}"
poetry run python -m grpc_tools.protoc \
    --python_out=src/gpcore_sdk \
    --grpc_python_out=src/gpcore_sdk \
    --proto_path=.tmp/proto_files \
    .tmp/proto_files/gpcore/v1/*.proto \
    .tmp/proto_files/gpcore/type/v1/*.proto

echo -e "${BLUE}  Generating buf validation files...${NC}"
poetry run python -m grpc_tools.protoc \
    --python_out=src/gpcore_sdk \
    --grpc_python_out=src/gpcore_sdk \
    --proto_path=.tmp/proto_files \
    .tmp/proto_files/buf/validate/*.proto \
    .tmp/proto_files/buf/validate/priv/*.proto

echo -e "${BLUE}  Generating Google RPC files...${NC}"
poetry run python -m grpc_tools.protoc \
    --python_out=src/gpcore_sdk \
    --grpc_python_out=src/gpcore_sdk \
    --proto_path=.tmp/proto_files \
    .tmp/proto_files/google/rpc/*.proto

echo -e "${BLUE}  Generating cloud v1 API files...${NC}"
poetry run python -m grpc_tools.protoc \
    --python_out=src/gpcore_sdk \
    --grpc_python_out=src/gpcore_sdk \
    --proto_path=.tmp/proto_files \
    .tmp/proto_files/gpcore/api/cloud/v1/*.proto

echo -e "${BLUE}  Generating API service files...${NC}"
for service_dir in .tmp/proto_files/gpcore/api/*/v*; do
    if [ -d "$service_dir" ] && [ "$service_dir" != *"/cloud/v1" ]; then
        service_name=$(basename $(dirname "$service_dir"))
        version=$(basename "$service_dir")
        echo -e "${BLUE}    Generating ${service_name} ${version}...${NC}"
        poetry run python -m grpc_tools.protoc \
            --python_out=src/gpcore_sdk \
            --grpc_python_out=src/gpcore_sdk \
            --proto_path=.tmp/proto_files \
            "$service_dir"/*.proto
    fi
done

echo -e "${YELLOW}🔧 Creating __init__.py files...${NC}"
find src/gpcore_sdk -type d -exec touch {}/__init__.py \;

echo -e "${YELLOW}🔧 Fixing import paths...${NC}"
# Fix gpcore imports
find src/gpcore_sdk -name "*.py" | grep pb2 | xargs sed -i 's/from gpcore\./from gpcore_sdk.gpcore./g'

# Fix buf imports  
find src/gpcore_sdk -name "*.py" | grep pb2 | xargs sed -i 's/from buf\./from gpcore_sdk.buf./g'

# Fix google imports (but keep google.protobuf as standard library)
find src/gpcore_sdk -name "*.py" | grep pb2 | xargs sed -i 's/from gpcore_sdk\.google\.protobuf/from google.protobuf/g'
find src/gpcore_sdk -name "*.py" | grep pb2 | xargs sed -i 's/from google\.rpc/from gpcore_sdk.google.rpc/g'

echo -e "${BLUE}🔧 Running linting and formatting...${NC}"
poetry run ruff check src/gpcore_sdk --fix --quiet
poetry run ruff format src/gpcore_sdk --quiet

echo -e "${BLUE}🧪 Testing SDK import...${NC}"
poetry run python -c "
from gpcore_sdk import GPortalClient, create_token_credentials
print('✅ SDK import successful!')

client = GPortalClient()
print('✅ Client creation successful!')
print('Available services:')
print('- Auth Service:', hasattr(client, 'auth'))
print('- Cloud Service:', hasattr(client, 'cloud'))  
print('- Payment Service:', hasattr(client, 'payment'))
print('- Metadata Service:', hasattr(client, 'metadata'))
print('- Admin Service:', hasattr(client, 'admin'))
print('- Network Service:', hasattr(client, 'network'))
print('- Gateway Service:', hasattr(client, 'gateway'))
client.close()
"

echo -e "${GREEN}🎉 SDK regeneration completed successfully!${NC}"
echo -e "${BLUE}📊 Generated files summary:${NC}"
echo "  - Total Python files: $(find src/gpcore_sdk -name "*.py" | wc -l)"
echo "  - Service stubs: $(find src/gpcore_sdk -name "*_pb2_grpc.py" | wc -l)"
echo "  - Message types: $(find src/gpcore_sdk -name "*_pb2.py" | wc -l)"

echo -e "${YELLOW}💡 To clean up temporary files, run: rm -rf .tmp${NC}"
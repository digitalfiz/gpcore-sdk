#!/bin/bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

show_help() {
    echo -e "${BLUE}GPCore SDK Development Helper${NC}"
    echo ""
    echo "Usage: $0 <command>"
    echo ""
    echo "Commands:"
    echo "  regenerate    Regenerate the SDK from latest protobuf specs"
    echo "  test          Test SDK import and basic functionality"
    echo "  clean         Clean up temporary files and cache"
    echo "  install       Install/update dependencies"
    echo "  check         Check SDK structure and imports"
    echo "  lint          Run ruff linting on custom SDK code"
    echo "  format        Format code with ruff"
    echo "  help          Show this help message"
}

cmd_regenerate() {
    echo -e "${BLUE}🔄 Regenerating SDK...${NC}"
    "$SCRIPT_DIR/regenerate_sdk.sh"
}

cmd_test() {
    echo -e "${BLUE}🧪 Testing SDK...${NC}"
    cd "$PROJECT_DIR"
    
    poetry run python -c "
import sys
sys.path.insert(0, 'src')

try:
    from gpcore_sdk import GPortalClient, create_token_credentials
    from gpcore_sdk.gpcore.api.cloud.v2 import requests_pb2 as cloud_requests
    from gpcore_sdk.gpcore.api.auth.v1 import requests_pb2 as auth_requests
    
    print('✅ SDK import successful!')
    
    client = GPortalClient()
    print('✅ Client creation successful!')
    
    # Test creating requests
    readiness_req = cloud_requests.ReadinessCheckRequest()
    user_req = auth_requests.GetUserRequest() 
    print('✅ Request creation successful!')
    
    print('Available services:')
    services = ['auth', 'cloud', 'payment', 'metadata', 'admin', 'network', 'gateway']
    for service in services:
        available = hasattr(client, service)
        status = '✅' if available else '❌'
        print(f'  {status} {service.capitalize()}Service: {available}')
    
    client.close()
    print('\\n🎉 All tests passed!')
    
except Exception as e:
    print(f'❌ Test failed: {e}')
    import traceback
    traceback.print_exc()
    sys.exit(1)
"
}

cmd_clean() {
    echo -e "${YELLOW}🧹 Cleaning up...${NC}"
    cd "$PROJECT_DIR"
    
    echo "  - Removing .tmp directory"
    rm -rf .tmp
    
    echo "  - Removing Python cache"
    find . -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null || true
    find . -name "*.pyc" -delete 2>/dev/null || true
    
    echo -e "${GREEN}✅ Cleanup complete!${NC}"
}

cmd_install() {
    echo -e "${BLUE}📦 Installing dependencies...${NC}"
    cd "$PROJECT_DIR"
    poetry install
    echo -e "${GREEN}✅ Dependencies installed!${NC}"
}

cmd_check() {
    echo -e "${BLUE}🔍 Checking SDK structure...${NC}"
    cd "$PROJECT_DIR"
    
    echo "SDK Structure:"
    echo "  - Total Python files: $(find src/gpcore_sdk -name "*.py" | wc -l)"
    echo "  - Service stubs: $(find src/gpcore_sdk -name "*_pb2_grpc.py" | wc -l)"
    echo "  - Message types: $(find src/gpcore_sdk -name "*_pb2.py" | wc -l)"
    echo "  - Custom modules: $(find src/gpcore_sdk -maxdepth 1 -name "*.py" ! -name "__*" | wc -l)"
    
    echo ""
    echo "Available API Services:"
    find src/gpcore_sdk/gpcore/api -name "rpc_pb2_grpc.py" | sed 's/.*\/api\/\([^\/]*\)\/\([^\/]*\)\/.*/  - \1 \2/' | sort
}

cmd_lint() {
    echo -e "${BLUE}🔍 Running ruff linting...${NC}"
    cd "$PROJECT_DIR"
    poetry run ruff check src/gpcore_sdk
    echo -e "${GREEN}✅ Linting complete!${NC}"
}

cmd_format() {
    echo -e "${BLUE}✨ Formatting code with ruff...${NC}"
    cd "$PROJECT_DIR"
    poetry run ruff format src/gpcore_sdk
    echo -e "${GREEN}✅ Formatting complete!${NC}"
}

# Main command handling
case "${1:-help}" in
    regenerate)
        cmd_regenerate
        ;;
    test)
        cmd_test
        ;;
    clean)  
        cmd_clean
        ;;
    install)
        cmd_install
        ;;
    check)
        cmd_check
        ;;
    lint)
        cmd_lint
        ;;
    format)
        cmd_format
        ;;
    help|--help|-h)
        show_help
        ;;
    *)
        echo -e "${RED}❌ Unknown command: $1${NC}"
        echo ""
        show_help
        exit 1
        ;;
esac
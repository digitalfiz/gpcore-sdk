# GPCore SDK

Python SDK for the GPortal GPCore API, generated from protobuf specifications.

## Installation

```bash
pip install gpcore-sdk
```

## Usage

### Basic Usage

```python
from gpcore_sdk import GPortalClient
from gpcore_sdk.gpcore.api.cloud.v2 import requests_pb2 as cloud_requests

# Create client with default SSL credentials
with GPortalClient() as client:
    # Make a readiness check (public endpoint)
    request = cloud_requests.ReadinessCheckRequest()
    response = client.cloud.ReadinessCheck(request)
    print(f"Service version: {response.version}")
```

### Authenticated Usage

```python
from gpcore_sdk import GPortalClient, create_token_credentials
from gpcore_sdk.gpcore.api.auth.v1 import requests_pb2 as auth_requests

# Create credentials with your API token
token = "your-api-token-here"
credentials = create_token_credentials(token)

with GPortalClient(credentials=credentials) as client:
    # Get user information
    request = auth_requests.GetUserRequest()
    response = client.auth.GetUser(request)
    print(f"User ID: {response.user.id}")
```

## Available Services

- **AuthService**: Authentication and OAuth client management
- **CloudService**: Project and node management
- **PaymentService**: Billing and payment operations
- **MetadataService**: Metadata management
- **AdminService**: Administrative operations
- **NetworkService**: Network configuration
- **GatewayService**: Gateway operations

## Development

### Quick Setup

```bash
# Using mise tasks (recommended)
mise run install     # Install dependencies
mise run test        # Test the SDK
mise run check       # Check SDK structure

# Or using scripts directly
./scripts/dev.sh install
./scripts/dev.sh test  
./scripts/dev.sh check
```

### Regenerating the SDK

When the GPortal API protobuf specifications are updated, regenerate the SDK:

```bash
# Using mise (recommended)
mise run regenerate

# Or using scripts directly
./scripts/dev.sh regenerate
./scripts/regenerate_sdk.sh
```

### Development Commands

Available via `mise run <task>` or `./scripts/dev.sh <command>`:

- `regenerate` - Regenerate SDK from latest protobuf specs
- `test` - Test SDK import and basic functionality  
- `clean` - Clean up temporary files and cache
- `install` - Install/update dependencies
- `check` - Check SDK structure and imports
- `lint` - Run ruff linting on custom SDK code
- `format` - Format code with ruff
- `dev` / `help` - Show available commands

List all tasks: `mise tasks`

### Manual Development

```bash
# Install dependencies
poetry install

# Run tests
poetry run python -c "from gpcore_sdk import GPortalClient; print('Import successful')"
```

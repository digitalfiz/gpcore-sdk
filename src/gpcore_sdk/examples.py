"""Usage examples for the GPCore SDK."""

from gpcore_sdk import GPortalClient, create_token_credentials
from gpcore_sdk.gpcore.api.auth.v1 import requests_pb2 as auth_requests
from gpcore_sdk.gpcore.api.cloud.v2 import requests_pb2 as cloud_requests


def basic_usage_example():
    """Basic usage example."""
    # Create client with default SSL credentials
    with GPortalClient() as client:
        # Make a readiness check (public endpoint)
        request = cloud_requests.ReadinessCheckRequest()
        response = client.cloud.ReadinessCheck(request)
        print(f"Service version: {response.version}")


def authenticated_usage_example():
    """Example using API token authentication."""
    # Replace with your actual API token
    token = "your-api-token-here"
    credentials = create_token_credentials(token)

    with GPortalClient(credentials=credentials) as client:
        # Get user information
        request = auth_requests.GetUserRequest()
        response = client.auth.GetUser(request)
        print(f"User ID: {response.user.id}")

        # List nodes in a project
        request = cloud_requests.ListNodesRequest(project_uuid="your-project-uuid")
        response = client.cloud.ListNodes(request)
        print(f"Found {len(response.nodes)} nodes")


def list_oauth_clients_example():
    """Example of listing OAuth clients."""
    token = "your-api-token-here"
    credentials = create_token_credentials(token)

    with GPortalClient(credentials=credentials) as client:
        request = auth_requests.ListClientsRequest()
        response = client.auth.ListClients(request)

        for client_info in response.clients:
            print(f"Client: {client_info.name} (ID: {client_info.id})")


if __name__ == "__main__":
    # Run basic example
    basic_usage_example()

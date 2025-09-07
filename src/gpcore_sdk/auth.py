"""Authentication utilities for GPCore SDK."""

import grpc


class TokenCredentials(grpc.AuthMetadataPlugin):
    """gRPC credentials plugin for API token authentication."""

    def __init__(self, token: str):
        self.token = token

    def __call__(self, context, callback):
        metadata = (("authorization", f"Bearer {self.token}"),)
        callback(metadata, None)


def create_token_credentials(token: str) -> grpc.ChannelCredentials:
    """Create gRPC credentials for API token authentication.

    Args:
        token: The API token

    Returns:
        gRPC channel credentials
    """
    call_credentials = grpc.metadata_call_credentials(TokenCredentials(token))
    ssl_credentials = grpc.ssl_channel_credentials()
    return grpc.composite_channel_credentials(ssl_credentials, call_credentials)

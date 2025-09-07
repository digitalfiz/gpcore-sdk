"""GPortal GPCore API Client."""


import grpc

from .gpcore.api.admin.v1 import rpc_pb2_grpc as admin_grpc
from .gpcore.api.auth.v1 import rpc_pb2_grpc as auth_grpc
from .gpcore.api.cloud.v2 import rpc_pb2_grpc as cloud_grpc
from .gpcore.api.gateway.v1 import rpc_pb2_grpc as gateway_grpc
from .gpcore.api.metadata.v1 import rpc_pb2_grpc as metadata_grpc
from .gpcore.api.network.v1 import rpc_pb2_grpc as network_grpc
from .gpcore.api.payment.v1 import rpc_pb2_grpc as payment_grpc


class GPortalClient:
    """Main client for interacting with the GPortal API."""

    def __init__(
        self,
        endpoint: str = "api.gportal.com:443",
        credentials: grpc.ChannelCredentials | None = None,
        options: list | None = None,
    ):
        """Initialize the GPortal client.

        Args:
            endpoint: The gRPC endpoint to connect to
            credentials: gRPC credentials for authentication
            options: Additional gRPC channel options
        """
        self.endpoint = endpoint

        if credentials is None:
            credentials = grpc.ssl_channel_credentials()

        if options is None:
            options = [
                ("grpc.keepalive_time_ms", 30000),
                ("grpc.keepalive_timeout_ms", 5000),
                ("grpc.keepalive_permit_without_calls", True),
                ("grpc.http2.max_pings_without_data", 0),
                ("grpc.http2.min_time_between_pings_ms", 10000),
                ("grpc.http2.min_ping_interval_without_data_ms", 300000),
            ]

        self._channel = grpc.secure_channel(endpoint, credentials, options=options)

        # Initialize service stubs
        self.auth = auth_grpc.AuthServiceStub(self._channel)
        self.cloud = cloud_grpc.CloudServiceStub(self._channel)
        self.payment = payment_grpc.PaymentServiceStub(self._channel)
        self.metadata = metadata_grpc.MetadataServiceStub(self._channel)
        self.admin = admin_grpc.AdminServiceStub(self._channel)
        self.network = network_grpc.NetworkServiceStub(self._channel)
        self.gateway = gateway_grpc.GatewayServiceStub(self._channel)

    def close(self):
        """Close the gRPC channel."""
        self._channel.close()

    def __enter__(self):
        return self

    def __exit__(self, exc_type, exc_val, exc_tb):
        self.close()

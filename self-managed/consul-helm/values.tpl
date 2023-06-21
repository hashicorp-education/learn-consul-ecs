# Contains values that affect multiple components of the chart.
global:
  # The main enabled/disabled setting.
  # If true, servers, clients, Consul DNS and the Consul UI will be enabled.
  enabled: true
  # The prefix used for all resources created in the Helm chart.
  name: consul
  # The Consul version to use.
  image: "hashicorp/consul:${consul_version}"
  # The name of the datacenter that the agents should register as.
  datacenter: ${datacenter}
  # Enables TLS across the cluster to verify authenticity of the Consul servers and clients.
  tls:
    enabled: true
  # Enables ACLs across the cluster to secure access to data and APIs.
  acls:
    # If true, automatically manage ACL tokens and policies for all Consul components.
    manageSystemACLs: true
# Configures values that configure the Consul server cluster.
server:
  enabled: true
  # The number of server agents to run. This determines the fault tolerance of the cluster.
  replicas: 3
  extraConfig: |
    {
      "connect": {
        "enable_serverless_plugin": true
      }
    }
# Contains values that configure the Consul UI.
ui:
  enabled: true
  # Registers a Kubernetes Service for the Consul UI as a LoadBalancer.
  service:
    type: LoadBalancer
# Configures and installs the automatic Consul Connect sidecar injector.
connectInject:
  enabled: true
# Configures and installs the Consul controller for managing custom resources.
controller:
  enabled: true
terminatingGateways:
  enabled: true
  defaults:
    replicas: 1
meshGateway:
  enabled: true
  replicas: 1
apiGateway:
  enabled: true
  image: "hashicorp/consul-api-gateway:${api_gateway_version}"
  managedGatewayClass:
    serviceType: LoadBalancer
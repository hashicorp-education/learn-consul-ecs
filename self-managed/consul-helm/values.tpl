global:
  # The main enabled/disabled setting.
  # If true, servers, clients, Consul DNS and the Consul UI will be enabled.
  enabled: true
  # The prefix used for all resources created in the Helm chart.
  name: consul
  # The Consul version to use.
  image: "hashicorp/consul:1.16.0-rc1"
  # The name of the datacenter that the agents should register as.
  datacenter: ${datacenter}
  tls:
    enabled: true
    enableAutoEncrypt: true
    verify: true
  acls:
    manageSystemACLs: true
  metrics:
    enabled: true
    defaultEnabled: true
server:
  enabled: true
  replicas: 3
connectInject:
  enabled: true
ui:
  enabled: true
  service:
    enabled: true
    type: LoadBalancer
apiGateway:
  enabled: true
  image: "hashicorp/consul-api-gateway:${api_gateway_version}"
  managedGatewayClass:
    serviceType: LoadBalancer
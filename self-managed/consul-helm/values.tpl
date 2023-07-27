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
  tls:
    enabled: false
  acls:
    manageSystemACLs: true
    bootstrapToken:
      secretName: bootstrap-token
      secretKey: token
  metrics:
    enabled: true
    defaultEnabled: true
server:
  enabled: true
  replicas: 3
  exposeService:
    # When enabled, deploys a Kubernetes Service to reach the Consul servers.
    enabled: true
    type: NodePort
    nodePort:
      http: 32500
      serf: 32301
connectInject:
  enabled: true
  apiGateway:
    manageExternalCRDs: true
    managedGatewayClass:
      serviceType: LoadBalancer
ui:
  enabled: true
  service:
    enabled: true
    type: LoadBalancer
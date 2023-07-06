global:
  # The main enabled/disabled setting.
  # If true, servers, clients, Consul DNS and the Consul UI will be enabled.
  enabled: true
  # The prefix used for all resources created in the Helm chart.
  name: consul
  # The Consul version to use.
  image: "hashicorp/consul:1.16.0"
  # The name of the datacenter that the agents should register as.
  datacenter: ${datacenter}
  tls:
    enabled: false
    enableAutoEncrypt: true
    caCert:
      secretName: ca-cert
      secretKey: tls.crt
    caKey:
      secretName: ca-key
      secretKey: tls.key
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
ui:
  enabled: true
  service:
    enabled: true
    #type: NodePort
    type: LoadBalancer
apiGateway:
  enabled: true
  image: "hashicorp/consul-api-gateway:${api_gateway_version}"
  managedGatewayClass:
    serviceType: LoadBalancer
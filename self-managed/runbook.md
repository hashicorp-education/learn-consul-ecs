terraform init
terraform apply --auto-approve
# wait 15 minutes for build
aws eks --region $(terraform output -raw region) update-kubeconfig --name $(terraform output -raw kubernetes_cluster_id)

export TF_VAR_CONSUL_HTTP_TOKEN=$(kubectl get --namespace consul secrets/consul-bootstrap-acl-token --template={{.data.token}} | base64 -d) && \
export TF_VAR_CONSUL_HTTP_ADDR=$(kubectl get services/consul-ui --namespace consul -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')

echo $TF_VAR_CONSUL_HTTP_ADDR && \
echo $TF_VAR_CONSUL_HTTP_TOKEN

export TF_VAR_CONSUL_APIGW_ADDR=http://$(kubectl get svc/api-gateway -o json | jq -r '.status.loadBalancer.ingress[0].hostname'):8080

echo $TF_VAR_CONSUL_APIGW_ADDR

# only frontend part of application is available
# check ECS services
aws ecs --region $(terraform output -raw region) list-services --cluster learn-consul

# get requirements for extending the mesh to ECS
export TF_VAR_CONSUL_CA_CERT=$(kubectl get --namespace consul secrets/consul-ca-cert -o jsonpath="{.data['tls\.crt']}" | base64 -d)

echo $TF_VAR_CONSUL_CA_CERT && \
echo $TF_VAR_CONSUL_HTTP_ADDR && \
echo $TF_VAR_CONSUL_HTTP_TOKEN

# deploy modified ECS services
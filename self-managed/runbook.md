terraform init
terraform apply --auto-approve
# wait 15 minutes for build
aws eks --region $(terraform output -raw region) update-kubeconfig --name $(terraform output -raw kubernetes_cluster_id)

export CONSUL_HTTP_TOKEN=$(kubectl get --namespace consul secrets/bootstrap-token --template={{.data.token}} | base64 -d) && \
export CONSUL_HTTP_ADDR=https://$(kubectl get services/consul-ui --namespace consul -o jsonpath='{.status.loadBalancer.ingress[0].hostname}') && \
kubectl get --namespace consul secrets/ca-cert -o jsonpath="{.data['tls\.crt']}" | base64 -d > ca.crt
export CONSUL_CACERT="$PWD"/ca.crt && \
export CONSUL_APIGW_ADDR=http://$(kubectl get svc/api-gateway -o json | jq -r '.status.loadBalancer.ingress[0].hostname'):8080

consul members

echo $CONSUL_HTTP_ADDR && \
echo $CONSUL_HTTP_TOKEN && \
echo $TF_VAR_CONSUL_APIGW_ADDR

# only frontend part of application is available
# check ECS services
aws ecs --region $(terraform output -raw region) list-services --cluster learn-consul

# get requirements for extending the mesh to ECS
export TF_VAR_CONSUL_CA_CERT=$(kubectl get --namespace consul secrets/ca-cert -o jsonpath="{.data['tls\.crt']}" | base64 -d) && \
export TF_VAR_CONSUL_SERVER_CA_CERT=$(kubectl get --namespace consul secrets/consul-server-cert -o jsonpath="{.data['tls\.crt']}" | base64 -d)

echo $TF_VAR_CONSUL_CA_CERT && \
echo $TF_VAR_CONSUL_SERVER_CA_CERT && \
echo $TF_VAR_CONSUL_HTTP_ADDR && \
echo $TF_VAR_CONSUL_HTTP_TOKEN

# deploy modified ECS services
# uncomment secrets-manager.tf
# uncomment ecs-services-and-tasks-with-consul.tf
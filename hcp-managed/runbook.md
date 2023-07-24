export HCP_CLIENT_ID=UEWyBTBey1nzMJZzo6sOcfNt31SjiaSX
export HCP_CLIENT_SECRET=M8L8GGk_xXQjGNSnE1ZpJoMl3PN3qjIns114WDo2OhHWy1iSofVQaSz2Rmub26sc
dr
eval $(dm)

terraform init
terraform apply --auto-approve
# wait 10-15 minutes for build

aws eks --region $(terraform output -raw region) update-kubeconfig --name $(terraform output -raw kubernetes_cluster_id)

export CONSUL_HTTP_TOKEN=$(terraform output -raw consul_root_token) && \
export CONSUL_HTTP_ADDR=$(terraform output -raw consul_url) && \
export CONSUL_APIGW_ADDR=http://$(kubectl get svc/api-gateway -o json | jq -r '.status.loadBalancer.ingress[0].hostname')

consul catalog services
# notice only half (3) of the hashicups microservices are in the mesh

aws ecs list-services --region $(terraform output -raw region) --cluster $(terraform output -raw ecs_cluster_name)
# notice the other half (3) of the hashicups microservices are in ECS
CTRL+C

echo $CONSUL_APIGW_ADDR
# Go to API gateway URL and see only frontend part of application is available

cp -f hashicups-ecs/ecs-services-and-tasks-with-consul.tf ecs-services-and-tasks.tf

terraform apply --auto-approve

consul catalog services
# notice now all (6) of the hashicups microservices are in the mesh

echo $CONSUL_APIGW_ADDR
# Go to API gateway URL and see the whole application works
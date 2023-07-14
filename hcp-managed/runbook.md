export HCP_CLIENT_ID=UEWyBTBey1nzMJZzo6sOcfNt31SjiaSX
export HCP_CLIENT_SECRET=M8L8GGk_xXQjGNSnE1ZpJoMl3PN3qjIns114WDo2OhHWy1iSofVQaSz2Rmub26sc
dr
eval $(dm)

terraform init
terraform apply --auto-approve
# wait 10-15 minutes for build

export CONSUL_HTTP_TOKEN=$(terraform output -raw consul_root_token) && \
export CONSUL_HTTP_ADDR=$(terraform output -raw consul_url)

consul catalog services
# notice there are no HashiCups microservices in the mesh

aws ecs list-services --region $(terraform output -raw region) --cluster $(terraform output -raw ecs_cluster_name)
# notice the HashiCups microservices are in ECS, but not integrated with Consul
CTRL+C

terraform output -raw hashicups_url
# Go to the HashiCups URL and see only the frontend part of application is available

cp -f hashicups-ecs/ecs-services-and-tasks-with-consul.tf ecs-services-and-tasks.tf

terraform apply --auto-approve

aws ecs list-services --region $(terraform output -raw region) --cluster $(terraform output -raw ecs_cluster_name)
# notice the HashiCups microservices have been modified in ECS
CTRL+C

consul catalog services
# notice now all 5 of the HashiCups microservices are in the mesh

terraform output -raw hashicups_url
# Go to the HashiCups URL and see the whole application works
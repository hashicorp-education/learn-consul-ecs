export HCP_CLIENT_ID=UEWyBTBey1nzMJZzo6sOcfNt31SjiaSX
export HCP_CLIENT_SECRET=M8L8GGk_xXQjGNSnE1ZpJoMl3PN3qjIns114WDo2OhHWy1iSofVQaSz2Rmub26sc
dr
eval $(dm)

terraform init
terraform apply --auto-approve
# wait 15 minutes for build

terraform output -raw consul_root_token

export CONSUL_HTTP_TOKEN=$(terraform output -raw ecs_cluster_name) && \
export CONSUL_HTTP_ADDR=$(terraform output -raw ecs_cluster_name) && \
export CONSUL_APIGW_ADDR=$(terraform output -raw ecs_cluster_name)

consul catalog services
# notice only half (3) of the hashicups microservices are in the mesh

aws ecs list-services --region $(terraform output -raw region) --cluster $(terraform output -raw ecs_cluster_name)
# notice the other half (3) of the hashicups microservices are in ECS
CTRL+C

echo $CONSUL_APIGW_ADDR
# Go to API gateway URL and see only frontend part of application is available

# remove .tf extension from ecs-services-and-tasks-without-consul.tf
# add .tf extension to end of ecs-service-and-task-with-consul.tf

terraform apply --auto-approve

consul catalog services
# notice now all (6) of the hashicups microservices are in the mesh

echo $CONSUL_APIGW_ADDR
# Go to API gateway URL and see the whole application works
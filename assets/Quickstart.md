# Instructions

## Pre-requisites

- Azure CLI
- Azure Subscription
- .NET Core 3.0
- powershell
- helm

## Setup

### Creating AKS clsuter with virtual node add on

* Execute the following
* Open VS Code Run as Admin

```cli

project_name=vn-take4
location=eastus
az group create -n $project_name -l $location
az configure --defaults location=$location group=$project_name

--Note: acr_name cannot have a hyphen
--KMN: changed acr_name to vntake4
acr_name=vnet4
az acr create --name $acr_name --sku Basic

vnet_name=$project_name
aci_subnet_name=aciSubnet
az network vnet create \
    --name $vnet_name \
    --address-prefixes 10.0.0.0/8 \
    --subnet-name $aci_subnet_name \
    --subnet-prefix 10.240.0.0/16

virtual_subnet_name=virtualSubnet
az network vnet subnet create \
    --vnet-name $vnet_name \
    --name $virtual_subnet_name \
    --address-prefixes 10.241.0.0/16

aci_subnet_id=$(az network vnet subnet show --vnet-name $vnet_name --name $aci_subnet_name --query id -o tsv)

virtual_subnet_id=$(az network vnet subnet show --vnet-name $vnet_name --name $virtual_subnet_name --query id -o tsv)

aks_cluster_name=$project_name
az aks create \
          --name $aks_cluster_name \
          --node-count 1 \
          --attach-acr $acr_name \
          --network-plugin azure \
          --aci-subnet-name $virtual_subnet_name \
          --vnet-subnet-id $aci_subnet_id \
          --enable-addons virtual-node \
          --generate-ssh-keys
Note: I used a system assigned identity
az aks install-cli

```

### Install KEDA

* Execute the following

```cli
curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
chmod 700 get_helm.sh
./get_helm.sh
helm repo add stable https://charts.helm.sh/stable

helm repo update
helm repo add kedacore https://kedacore.github.io/charts
az aks get-credentials -n $project_name
kubectl create namespace keda
helm install keda kedacore/keda --namespace keda

```

### Creating a new Azure Service Bus namespace & queue

* Execute the following

```cli

servicebus_namespace=$project_name
az servicebus namespace create --name $servicebus_namespace --sku basic

keda_connection_string=$(az servicebus namespace authorization-rule keys list  --namespace-name $servicebus_namespace --name RootManageSharedAccessKey --query primaryConnectionString -o tsv)

queue_name=orders
az servicebus queue create --namespace-name $servicebus_namespace --name $queue_name

authorization_rule_name=order-consumer
az servicebus queue authorization-rule create --namespace-name $servicebus_namespace --queue-name $queue_name --name $authorization_rule_name --rights Listen

queue_connection_string=$(az servicebus queue authorization-rule keys list --namespace-name $servicebus_namespace --queue-name $queue_name --name $authorization_rule_name --query primaryConnectionString -o tsv)

demo_app_namespace=keda-dotnet-sample
kubectl create namespace $demo_app_namespace

keda_servicebus_secret=keda-servicebus-secret
kubectl create secret generic $keda_servicebus_secret --from-literal=keda-connection-string=$keda_connection_string -n $demo_app_namespace

kubectl create secret generic order-consumer-secret --from-literal=queue-connection-string=$queue_connection_string -n $demo_app_namespace

```

### Deploying demo app

* Execute the following

```cli

kubectl apply -f deploy/deploy-app.yaml --namespace $demo_app_namespace

kubectl get pod -n $demo_app_namespace -o wide

--Wait for the pod to be in Running state before proceeding to the next step.

kubectl apply -f deploy/deploy-autoscaling.yaml --namespace $demo_app_namespace

```

### Deploying Keda scaledobject

* Execute the following

```cli

kubectl describe scaledobject order-processor-scaler -n $demo_app_namespace

kubectl get deployments --namespace $demo_app_namespace -o wide

```

### setting up and running order generator

* Execute the following

```cli

monitor_authorization_rule_name=keda-monitor-send
az servicebus queue authorization-rule create --namespace-name $servicebus_namespace --queue-name $queue_name --name $monitor_authorization_rule_name --rights Listen Send

MONITOR_CONNECTION_STRING=$(az servicebus queue authorization-rule keys list --namespace-name $servicebus_namespace --queue-name $queue_name --name $monitor_authorization_rule_name --query primaryConnectionString -o tsv)

echo $MONITOR_CONNECTION_STRING

```

* In `src/Keda.Samples.Dotnet.OrderGenerator/Program.cs`, replace  `MONITOR_CONNECTION_STRING` with the above value

* in a powershell terminal, run: `dotnet run --project .\src\Keda.Samples.Dotnet.OrderGenerator\Keda.Samples.Dotnet.OrderGenerator.csproj`

* When prompted: "Let's queue some orders, how many do you want?" enter `300` 

* In the bash shell: run `watch kubectl get pod -n $demo_app_namespace -o wide`

# Instructions

## Pre-requisites

- Completion of Module 1 and 2

### Enable virtual node add on

* Execute the following

```cli

az provider register --namespace Microsoft.ContainerInstance
az aks enable-addons \
    --name <aks-cluster-name> \
    --addons virtual-node \
    --subnet-name <aci-subnet-name>

```

### Deploying updated demo app

* Execute the following

```cli

cd module3

kubectl apply -f deploy/deploy-app.yaml --namespace $demo_app_namespace

kubectl get pod -n $demo_app_namespace -o wide

```

### setting up and running order generator

* Execute the following

```powershell

`dotnet run --project .\src\Keda.Samples.Dotnet.OrderGenerator\Keda.Samples.Dotnet.OrderGenerator.csproj`

* When prompted: "Let's queue some orders, how many do you want?" enter `300` 

```

```cli

watch kubectl get pod -n $demo_app_namespace -o wide

```

# Welcome to: Module 2: Application Deployment and Testing with Azure Load Testing

### Install KEDA

* Execute the following

```

rg_name=[name of rg created in module 1]
akscluster_name=[name of aks cluster created in module 1]


helm repo add kedacore https://kedacore.github.io/charts
helm repo update

az aks get-credentials --admin -g $rg_name --name $akscluster_name

kubectl create namespace keda
helm install keda kedacore/keda --namespace keda
```

### Creating a new Azure Service Bus namespace & queue

* Execute the following

```cli
project_name=servicebus
servicebus_namespace=$project_name

az servicebus namespace create --name $servicebus_namespace -g $rg_name --sku basic

keda_connection_string=$(az servicebus namespace authorization-rule keys list -g $rg_name --namespace-name $servicebus_namespace --name RootManageSharedAccessKey --query primaryConnectionString -o tsv)

queue_name=orders
az servicebus queue create -g $rg_name --namespace-name $servicebus_namespace --name $queue_name

authorization_rule_name=order-consumer
az servicebus queue authorization-rule create -g $rg_name --namespace-name $servicebus_namespace --queue-name $queue_name --name $authorization_rule_name --rights Listen

queue_connection_string=$(az servicebus queue authorization-rule keys list -g $rg_name --namespace-name $servicebus_namespace --queue-name $queue_name --name $authorization_rule_name --query primaryConnectionString -o tsv)

demo_app_namespace=order-processor
kubectl create namespace $demo_app_namespace

keda_servicebus_secret=keda-servicebus-secret
kubectl create secret generic $keda_servicebus_secret --from-literal=keda-connection-string=$keda_connection_string -n $demo_app_namespace

kubectl create secret generic order-consumer-secret --from-literal=queue-connection-string=$queue_connection_string -n $demo_app_namespace

demo_web_namespace=order-portal
kubectl create namespace $demo_web_namespace
kubectl create secret generic $keda_servicebus_secret --from-literal=keda-connection-string=$keda_connection_string -n $demo_web_namespace

kubectl create secret generic order-consumer-secret --from-literal=queue-connection-string=$queue_connection_string -n $demo_web_namespace


```

### Deploying order processor app

* Execute the following

```cli
cd [file path to module2]
kubectl apply -f deploy/deploy-app.yaml --namespace $demo_app_namespace

kubectl get pod -n $demo_app_namespace -o wide

--Wait for the pod to be in Running state before proceeding to the next step.

kubectl apply -f deploy/deploy-autoscaling.yaml --namespace $demo_app_namespace

```
* Alternative the following:

```
kubectl apply -f https://raw.githubusercontent.com/Azure/aks-advanced-autoscaling/module2/docs/module2/deploy/deploy-app.yaml -n $demo_app_namespace

kubectl get pod -n $demo_app_namespace -o wide

--Wait for the pod to be in Running state before proceeding to the next step.

kubectl apply -f https://raw.githubusercontent.com/Azure/aks-advanced-autoscaling/module2/docs/module2/deploy/deploy-autoscaling.yaml -n $demo_app_namespace

```
### Deploying Keda scaledobject

* Execute the following

```cli

kubectl describe scaledobject order-processor-scaler -n $demo_app_namespace

kubectl get deployments --namespace $demo_app_namespace -o wide

```

### Deploying web order portal

* Execute the following
```
cd [file path to module2]
kubectl apply -f deploy/deploy-web.yaml --namespace $demo_web_namespace

kubectl get pod,svc -n $demo_web_namespace -o wide
```

* Alternative the following:

```
kubectl apply -f https://raw.githubusercontent.com/Azure/aks-advanced-autoscaling/module2/docs/module2/deploy/deploy-web.yaml -n $demo_web_namespace

kubectl get pod,svc -n $demo_web_namespace -o wide
```

### Setting up and running service bus

* Execute the following

```cli

monitor_authorization_rule_name=keda-monitor-send
az servicebus queue authorization-rule create --namespace-name $servicebus_namespace --queue-name $queue_name --name $monitor_authorization_rule_name --rights Listen Send

MONITOR_CONNECTION_STRING=$(az servicebus queue authorization-rule keys list --namespace-name $servicebus_namespace --queue-name $queue_name --name $monitor_authorization_rule_name --query primaryConnectionString -o tsv)

echo $MONITOR_CONNECTION_STRING 
```
### Deploying order processor app

* Execute the following

kubectl apply -f deploy/deploy-app.yaml --namespace $demo_web_namespace

kubectl get pod -n $demo_web_namespace -o wide

### Watching the pods scale

* In the bash shell: run `watch kubectl get pod -n $demo_app_namespace -o wide`

### Creating Azure Load Testing resource, a centralized place to view and manage test plans, test results, and related artifacts

If you already have a Load Testing resource, skip this section.

To create a Load Testing resource:

1. Sign in to the Azure portal (https://portal.azure.com) by using the credentials for your Azure subscription.

2. Select the menu button in the upper-left corner of the portal, and then select + Create a resource.

(assets/create-resource.png)

3. Use the search bar to find Azure Load Testing.

4. Select Azure Load Testing.

5. On the Azure Load Testing pane, select Create.

6. Provide the following information to configure your new Azure Load Testing resource:
(assets/create-azure-load-testing.png)

TABLE 1
Field	Description
Subscription	Select the Azure subscription that you want to use for this Azure Load Testing resource.
Resource group	Select an existing resource group. Or select Create new, and then enter a unique name for the new resource group.
Name	Enter a unique name to identify your Azure Load Testing resource.
The name can't contain special characters, such as \/""[]:|<>+=;,?*@&, or whitespace. The name can't begin with an underscore (_), and it can't end with a period (.) or a dash (-). The length must be 1 to 64 characters.
Location	Select a geographic location to host your Azure Load Testing resource.





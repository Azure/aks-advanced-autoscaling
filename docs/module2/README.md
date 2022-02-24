# Welcome to: Module 2: Application Deployment and Testing with Azure Load Testing

### Install KEDA

* Execute the following

```

rg_name=[name of rg created in module 1]
akscluster_name=[name of aks cluster created in module 1]


helm repo add kedacore https://kedacore.github.io/charts
helm repo update

az aks get-credentials --admin --name $rg_name --resource-group $akscluster_name

kubectl create namespace keda
helm install keda kedacore/keda --namespace keda
```

### Creating a new Azure Service Bus namespace & queue

* Execute the following

```cli
project_name=servicebus
servicebus_namespace=$project_name

az servicebus namespace create --name $servicebus_namespace --sku basic

keda_connection_string=$(az servicebus namespace authorization-rule keys list  --namespace-name $servicebus_namespace --name RootManageSharedAccessKey --query primaryConnectionString -o tsv)

queue_name=orders
az servicebus queue create --namespace-name $servicebus_namespace --name $queue_name

authorization_rule_name=order-consumer
az servicebus queue authorization-rule create --namespace-name $servicebus_namespace --queue-name $queue_name --name $authorization_rule_name --rights Listen

queue_connection_string=$(az servicebus queue authorization-rule keys list --namespace-name $servicebus_namespace --queue-name $queue_name --name $authorization_rule_name --query primaryConnectionString -o tsv)

demo_app_namespace=order-processor
kubectl create namespace $demo_app_namespace

keda_servicebus_secret=keda-servicebus-secret
kubectl create secret generic $keda_servicebus_secret --from-literal=keda-connection-string=$keda_connection_string -n $demo_app_namespace

kubectl create secret generic order-consumer-secret --from-literal=queue-connection-string=$queue_connection_string -n $demo_app_namespace

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

### Deploying Keda scaledobject

* Execute the following

```cli

kubectl describe scaledobject order-processor-scaler -n $demo_app_namespace

kubectl get deployments --namespace $demo_app_namespace -o wide

```

### Setting up and running service bus

* Execute the following

```cli

monitor_authorization_rule_name=keda-monitor-send
az servicebus queue authorization-rule create --namespace-name $servicebus_namespace --queue-name $queue_name --name $monitor_authorization_rule_name --rights Listen Send

MONITOR_CONNECTION_STRING=$(az servicebus queue authorization-rule keys list --namespace-name $servicebus_namespace --queue-name $queue_name --name $monitor_authorization_rule_name --query primaryConnectionString -o tsv)

echo $MONITOR_CONNECTION_STRING | base64

```
### Deploying order processor app

* Execute the following
-- Copy the $MONITOR_CONNECTION_STRING from above value and paste into eploy\deploy-web.yaml servicebus-connectionstring
demo_web_namespace=order-portal

kubectl apply -f deploy/deploy-app.yaml --namespace $demo_web_namespace

kubectl get pod -n $demo_web_namespace -o wide

### Watching the pods scale

* In the bash shell: run `watch kubectl get pod -n $demo_app_namespace -o wide`

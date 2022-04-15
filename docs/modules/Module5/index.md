
# Building and Scaling Azure Container Apps

## Azure Container Apps Features

* Fully managed serverless container service for building and deploying modern apps at scale.
* Write code using your preferred programming language or framework, and build microservices with full support for [Distributed Application Runtime (DAPR)](https://dapr.io/)
* Scale dynamically based on HTTP traffic or events powered by [Kubernetes Event-Driven Autoscaling (KEDA)](keda.sh). 

## Pre-requisites

* Completion of Module 1
* Completion of Module 2
* Following variables are set (from Moule 2):
  * rg_name
  * monitor_connection_string

## Setup

* install the Azure Container Apps extension for the CLI

```cli
az extension add --name containerapp
az provider register --namespace Microsoft.App
```

* set the following environment variables

```cli
CONTAINERAPPS_ENVIRONMENT="order"
app_location=eastus2
```

## Create Azure Container Apps Environment

```cli
az containerapp env create \
  --name $CONTAINERAPPS_ENVIRONMENT \
  --resource-group $rg_name \
  --location $app_location
```
## Create a container app

```cli
az deployment group create --resource-group "$rg_name" \
  --template-file tools/deploy/module5/order-processor-app.json \
  --parameters \
    environment_name="$CONTAINERAPPS_ENVIRONMENT" \
    queue_connection_string="$monitor_connection_string" \
    location="$app_location"  
```

## Scaling Container App with Azure Load Testting (ALT)

* In **Module2** ALT was set up to publish messages to ASB queue to scale the demo app.
* For this module, we just need to re-run the same test, and observe scaling of the pod on virtual nodes
* On Azure Load Testing portal page, in `Test` menu, select the test script that was created in Module 2, and click **run**
* At the bottom of Run Review dialog box, click **Run**    

## Observing Scaling of Container App

* Wait until test status shows "Executing"
* On Azure Portal, search of **Container Apps**
* On **Container Apps** home page, select **Metrics** from left hand menu
* On the new chart set up, select **CPU Usage Nanocores** under **Metric** dropdown
* Set the time range to **Last 30 minutes**
* on the selected chart, select "Add Filter"
* Under the **Property** dropdown select **Replica**
* Under the **Values**, you will see multiple replicas of **order-processor** listed
* select one or more replicas to see their CPU usage as they consume messages inserted in the **orders** queue by ALT



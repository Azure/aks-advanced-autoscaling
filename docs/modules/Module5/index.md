az extension add --name containerapp
az provider register --namespace Microsoft.App
CONTAINERAPPS_ENVIRONMENT="order"
app_location=eastus2
rg_name=adv-autoscaling-rg

az containerapp env create \
  --name $CONTAINERAPPS_ENVIRONMENT \
  --resource-group $rg_name \
  --location $app_location

order_processor_image='ghcr.io/kedacore/sample-dotnet-worker-servicebus-queue:latest'  

az containerapp create \
  --image $order_processor_image \
  --name order-processor-app \
  --resource-group $rg_name \
  --environment $CONTAINERAPPS_ENVIRONMENT  


queue_name=orders
servicebus_namespace=adv-autoscaling
authorization_rule_name=order-consumer
queue_connection_string=$(az servicebus queue authorization-rule keys list -g $rg_name --namespace-name $servicebus_namespace --queue-name $queue_name --name $authorization_rule_name --query primaryConnectionString -o tsv)

asb_queue_primary_key=$(az servicebus queue authorization-rule keys list -g $rg_name --namespace-name $servicebus_namespace --queue-name $asb_queue --name $asb_queue_key_name --query primaryKey -o tsv)

az deployment group create --resource-group "$rg_name" \
  --template-file tools/deploy/module5/order-processor-app.json \
  --parameters \
    environment_name="$CONTAINERAPPS_ENVIRONMENT" \
    queue_connection_string="$queue_connection_string" \
    location="$app_location"  

### Scaling on Virtual Nodes with ALT

* In **Module2** ALT was set up to publish messages to ASB queue to scale the demo app.
* For this module, we just need to re-run the same test, and observe scaling of the pod on virtual nodes
* On Azure Load Testing portal page, in `Test` menu, select the test script that was created in Module 2, and click **run**
* At the bottom of Run Review dialog box, click **Run**    


LOG_ANALYTICS_WORKSPACE_CLIENT_ID=`az containerapp env show --name $CONTAINERAPPS_ENVIRONMENT --resource-group $rg_name --query properties.appLogsConfiguration.logAnalyticsConfiguration.customerId --out tsv`

az monitor log-analytics query \
  --workspace $LOG_ANALYTICS_WORKSPACE_CLIENT_ID \
  --analytics-query "ContainerAppConsoleLogs_CL | where ContainerAppName_s == 'order-processor-app' " \
  --out table
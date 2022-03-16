#### First, set the values of the variables (SETTING ALL VARIABLES section)
#### Then run the rest of the script (SCRIPT EXECUTION section)  

## Note: if your value set contains spaces please enclose the value in double quotes.
## Also, please make sure to run the following commands from same command directory 
## as the location of LvLUpAutoscalingLoadTest.jmx in order to let the "-F file=" parameter 
## load the jmx content correctly (use cd to set your command directory) </br>

### *** BEGIN - SETTING ALL VARIABLES
directory_of_LvLUpAutoscalingLoadTestjmx="[cd path of LvLUpAutoscalingLoadTest.jmx]"
subscription=[your subscription id used in Module 1]
rg_name=[name of resource group created in Module 1]
servicebus_namespace=[name of your azure service bus namespace]  
azure_key_vault=[your azure key vault name created in Module 1]
alt=[your azure load testing instance name created in Module 1]
## set the value of the azure service bus endpoint uri to test - e.g.: "asbnamespace.servicebus.windows.net" - no http(s) prefix
asb_endpoint_uri=[your asb uri]

### *** END - SETTING ALL VARIABLES

### BEGIN - SCRIPT EXECUTION - copy, paste, run

# Unless you are already logged in, 'az login'  will open a browser window to let you authenticate. Once authenticated, the script will continue running 
cd "$directory_of_LvLUpAutoscalingLoadTestjmx"
az login
az account set -s $subscription 
asb_queue=orders 
asb_queue_key_name=keda-monitor-send

asb_uri="https://"$servicebus_namespace".servicebus.windows.net/"$asb_queue"/messages"
asb_queue_primary_key=$(az servicebus queue authorization-rule keys list -g $rg_name --namespace-name $servicebus_namespace --queue-name $asb_queue --name $asb_queue_key_name --query primaryKey -o tsv)
echo $asb_queue_primary_key

get_sas_token() {
    local ASB_URI=$1
    local SHARED_ACCESS_KEY_NAME=$2
    local SHARED_ACCESS_KEY=$3
    local EXPIRY=${EXPIRY:=$((60 * 60 * 8))} # Setting default token expiration at 8 hours

    local ENCODED_URI=$(echo -n $ASB_URI | jq -s -R -r @uri)
    local TTL=$(($(date +%s) + $EXPIRY))
    local UTF8_SIGNATURE=$(printf "%s\n%s" $ENCODED_URI $TTL | iconv -t UTF-8)

    local HASH=$(echo -n "$UTF8_SIGNATURE" | openssl sha256 -hmac $SHARED_ACCESS_KEY -binary | base64)
    local ENCODED_HASH=$(echo -n $HASH | jq -s -R -r @uri)

    echo -n "SharedAccessSignature sr=$ENCODED_URI&sig=$ENCODED_HASH&se=$TTL&skn=$SHARED_ACCESS_KEY_NAME"
}

sastoken=$(get_sas_token $asb_uri $asb_queue_key_name $asb_queue_primary_key)
secretvalue=$sastoken
secret_name="sastoken"

## get current user upn
upn=$(az ad signed-in-user show --query userPrincipalName -o tsv)
## add access policy for current user to azure key vault
az keyvault set-policy -g $rg_name -n $azure_key_vault --secret-permissions all --upn $upn

# this will set the secret expiration in 8 hours from current date/time
expiredate=$(date +%Y-%m-%d'T'%H:%M:%S'Z' -d "$(date) + 8 hours")

az keyvault secret set --name $secret_name --vault-name $azure_key_vault --value "$secretvalue" --subscription $subscription --expires "$expiredate"

secret_uri=$(az keyvault secret show --name $secret_name --vault-name $azure_key_vault --query id -o tsv)
$secret_uri

## Default value already set for the load test instance that we are going to create. Feel free to keep it as-is or modify
testname="LvlUpNewTest"

## Values are already set. No need to change. Modify only if you would like to use different ones. 
testdate=$(date)
testdescription="Level Up Azure Load Testing Instance - Created on: $testdate"

## constant values - do not change unless instructed by trainer
arm_apiversion="api-version=2021-12-01-preview"
alt_apiversion="api-version=2021-07-01-preview"

## formatting resourceId string based on submitted variables 
resourceId="/subscriptions/"$subscription"/resourcegroups/"$rg_name"/providers/microsoft.loadtestservice/loadtests/"$alt

## formatting management endpoint url based on submitted variables 
armEndpoint="https://management.azure.com"$resourceId"?$arm_apiversion"

accessToken=$(az account get-access-token --resource "https://management.core.windows.net" --query accessToken -o tsv) 

hdr_authorization="Authorization: Bearer $accessToken"
hdr_content_type="Content-Type: application/json"

dataPlaneURI=$(curl -G -H "$hdr_authorization" -H "$hdr_content_type" $armEndpoint | jq -r .properties.dataPlaneURI) 

# utility function to create random guid
uuid()
{
    local N B C='89ab'

    for (( N=0; N < 16; ++N ))
    do
        B=$(( $RANDOM%256 ))

        case $N in
            6)
                printf '4%x' $(( B%16 ))
                ;;
            8)
                printf '%c%x' ${C:$RANDOM%${#C}:1} $(( B%16 ))
                ;;
            3 | 5 | 7 | 9)
                printf '%02x-' $B
                ;;
            *)
                printf '%02x' $B
                ;;
        esac
    done

    echo
}

testId=$(uuid) # do not change

# get access token for Azure Load Testing API endpoint
accessToken=$(az account get-access-token --resource "https://loadtest.azure-dev.com" --query accessToken -o tsv) 

## Number of Instances to run the test
EngineInstancesCount=1

## random id for the metrics - no need to change 
passFailMetrics1Guid=$(uuid) 
passFailMetrics2Guid=$(uuid) 

#
testJson=$(cat <<EOF
{
    "resourceId": "$resourceId",
    "testId": "$testId",
    "description": "$testdescription",
    "displayName": "$testname",
    "loadTestConfig": {
        "engineSize": "m",
        "engineInstances": $EngineInstancesCount
    },
    "secrets": {
        "sastoken": {
        "value": "$secret_uri",
        "type": "AKV_SECRET_URI"
        }
    },
    "environmentVariables": {
        "endpoint_uri": "$asb_endpoint_uri"
    },
    "passFailCriteria": {
        "passFailMetrics": {
            "$passFailMetrics1Guid": {
                "clientmetric": "response_time_ms",
                "aggregate": "avg",
                "condition": ">",
                "value": 500,
                "action": "continue",
                "result": null,
                "actualValue": 0
            },
            "$passFailMetrics2Guid": {
                "clientmetric": "error",
                "aggregate": "percentage",
                "condition": ">",
                "value": 30,
                "action": "continue",
                "result": null,
                "actualValue": 0
            }
        }
    }
}
EOF
)

hdr_authorization="Authorization: Bearer $accessToken"
hdr_content_type="Content-Type: application/merge-patch+json"

## set the Create Load Test API Endpoint URI 
loadCreateTestURI="https://"$dataPlaneURI"/loadtests/"$testId"?$alt_apiversion"
loadCreateTestResponse=$(curl $loadCreateTestURI -X PATCH -H "$hdr_authorization" -H "$hdr_content_type" -d "$testJson")

echo "****** Begin - Create Test API Response"
echo $loadCreateTestResponse
echo "****** End - Create Test API Response"

### The previous command should result in a json output with the properties of the Test instance just created.
### If you see a json output and no error (or null) value - process is working fine

fileid=$(uuid)
hdr_authorization="Authorization: Bearer $accessToken"
validateUploadFileTestURI="https://$dataPlaneURI/file/$fileid:validate?"$alt_apiversion
validateUploadFileTestResponse=$(curl $validateUploadFileTestURI -w "%{http_code}" -H "$hdr_authorization" -F "file=@LvLUpAutoscalingLoadTest.jmx")

## Now we will upload the jmx to the test with the next sequence of commands
uploadFileTestURI="https://$dataPlaneURI/loadtests/$testId/files/$fileid?"$alt_apiversion

## Please make sure to run the following from same command directory as the location of LvLUpAutoscalingLoadTest.jmx 
## in order to let the -F file= parameter load the jmx content correctly

uploadFileTestURIResponse=$(curl $uploadFileTestURI -X PUT -w "%{http_code}" -H "$hdr_authorization" -F "file=@LvLUpAutoscalingLoadTest.jmx")

### END - SCRIPT EXECUTION


### BEGIN - SOME FINAL CHECKS

## Let's verify that we got a http code 200 = OK for the Test File upload validation
RESPONSE_200_OK="200"
if [[ "$validateUploadFileTestResponse" == *"$RESPONSE_200_OK"* ]]
then 
    echo -e "\n\n*** STATUS OK *** :-) --> File ID is available  OK to continue"
else
    echo -e "\n\n*** IMPORTANT *** :'-( ***: File ID validation failed - Stop Executing any further and verify the error"
    echo -e "Status: "$validateUploadFileTestResponse
fi

## Let's verify that we got a http code 201 = OK for the Test creation
RESPONSE_201_OK="201"
if [[ "$uploadFileTestURIResponse" == *"$RESPONSE_201_OK"* ]]
then 
    echo -e "\n\n*** STATUS OK *** :-) --> Jmx File Uploaded - OK to continue"
else
    echo -e "\n\n*** IMPORTANT *** :'-( ***: Jmx File Not Uploaded - Stop Executing any further and verify the error"
    echo -e "Status: "$uploadFileTestURIResponse
fi
### END - SOME FINAL CHECKS

### You can also check in the Azure portal that the Test is present and configured correctly (refer to README)

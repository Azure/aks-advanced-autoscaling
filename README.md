# Welcome to: Module 4: Configure Keda Using Http Metrics & Open Service Mesh and Testing with Azure Load Testing

### Install KEDA

* Execute the following
```
az aks enable-addons --addons open-service-mesh -g 'resource_group' -n 'aks_cluster-name'

az aks show -g 'resource_group' -n 'aks_cluster-name'  --query 'addonProfiles.openServiceMesh.enabled'
```

### Verify the status of OSM

* Execute the following

```

kubectl get deployments -n kube-system --selector app.kubernetes.io/name=openservicemesh.io
kubectl get pods -n kube-system --selector app.kubernetes.io/name=openservicemesh.io
kubectl get services -n kube-system --selector app.kubernetes.io/name=openservicemesh.io
```

### Installing Prometheus via helm chart kube-prometheus-stack

* Execute the following

```
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
helm install prometheus \
prometheus-community/kube-prometheus-stack -f values.yaml \
--namespace monitoring \
--create-namespace

```

### Disabled metrics scapping from components that AKS don't expose.

* Execute the following

```
helm upgrade prometheus \
prometheus-community/kube-prometheus-stack -f values.yaml \
--namespace monitoring \
--set kubeEtcd.enabled=false \
--set kubeControllerManager.enabled=false \
--set kubeScheduler.enabled=false

```

### In OSM CLI and enabling OSM metrics for apps

* Execute the following


```
OSM_VERSION=v0.11.1
curl -sL "https://github.com/openservicemesh/osm/releases/download/$OSM_VERSION/osm-$OSM_VERSION-linux-amd64.tar.gz" | tar -vxzf -
sudo mv ./linux-amd64/osm /usr/local/bin/osm
sudo chmod +x /usr/local/bin/osm

osm metrics enable --namespace "app_namespace, app_namespace"
```
### Query to run in Prometheus to pull http metrics

```
sum(rate(envoy_cluster_upstream_rq_xx{envoy_cluster_name="order-web",source_service="ingress-name"}[1m]))
```
### Create KEDA ScaledObject based on Query

```

```


#  About this workshop


At the core of practically all Kubernetes applications is a Deployment resource. A Deployment is a resource that defines how our workload, in the form of containers inside Pods, should be executed. Deployment scaling can be controlled with a HorizontalPodAutoscaler (HPA) resource to account for varying capacity demand. Managing workloads with Deployments and HPAs works well if our application sees slowly varying capacity demand. However, with the shift towards microservices, event-driven driven architectures, and functions (which handle one or possibly a few events/requests and then terminate), this form of workload management is far from ideal.
 
That's where KEDA comes in! This workshop intends to dive deeper into workloads that require further optimized scaling for performance or that are based on custom scaling metrics that are not easily implemented with only CA and HPA.
 
In attending this LevelUp Workshop you will learn more about the following :
- Build knowledge around advanced scaling options in AKS from an application centric point of view.
- Deploy a scenario which leverages KEDA to scale workloads based on event-driven scalers like Azure Service Bus Queue.
- Deploy a scenario which leverages KEDA and Open Service Mesh to scale workloads based on HTTP request metrics.
- Deploy a scenario which leverages AKS virtual nodes for fast scaling to Azure Container Instances.
- Test the scaling mechanisms using Azure Load Testing"

Slides

- [Slides](assets/slides/ppt.pttx)

Diagrams

- ![Architecture - placeholder](assets/images/levelup-architecture.png)



# Contributors

<ul class="list-style-none">
{% for contributor in site.github.contributors %}
  <li class="d-inline-block mr-1">
     <a href="{{ contributor.html_url }}"><img src="{{ contributor.avatar_url }}" width="32" height="32" alt="{{ contributor.login }}"/></a>
  </li>
{% endfor %}
</ul>


# Trademarks

This project may contain trademarks or logos for projects, products, or services. Authorized use of Microsoft 
trademarks or logos is subject to and must follow 
[Microsoft's Trademark & Brand Guidelines](https://www.microsoft.com/en-us/legal/intellectualproperty/trademarks/usage/general).
Use of Microsoft trademarks or logos in modified versions of this project must not cause confusion or imply Microsoft sponsorship.
Any use of third-party trademarks or logos are subject to those third-party's policies.

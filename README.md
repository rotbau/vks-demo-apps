# VKS Demo Apps
The applications in this git repository can be used to demonstrate basic functionality of VKS clusters. They should also work with upstream compliant Kubernetes clusters.

## Demo Applications

- antrea/ - examples of egress and external pool
- argocd/ - example manifest for installing ArgoCD on a workload cluster using Supervisor ArgoCD Operator
- autoscaler/ - example cluster manifest, autoscaler package values yaml and test application on VKS
- clusters/ - example VKS cluster manifests
- istio/ - example data value for istio VKS package and test app
- kuard/ - simple example stateless app with service options (note Kuard container appears to have disappeared)
- logging/ - example fluent-bit configurations for Supervisor and VKS clusters
- scripts - helpful scripts to use
- wordpress/ - stateful deployment of mysql and wordpress using persistent storage with various service options



NOTICE: THIS SOFTWARE IS INTENTED FOR DEMONSTRATION PURPOSES ONLY AND THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
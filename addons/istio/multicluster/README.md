# Installing Istio Multicluster VKS Package

https://techdocs.broadcom.com/us/en/vmware-cis/vcf/vsphere-supervisor-services-and-standalone-components/latest/managing-vsphere-kuberenetes-service-clusters-and-workloads/installing-standard-packages-on-tkg-service-clusters/installing-standard-packages-on-tkg-cluster-using-tkr-for-vsphere-8-x/installaing-and-using-istio/using-istio/configure-istio-multi-clusters.html

https://techdocs.broadcom.com/us/en/vmware-cis/vcf/vsphere-supervisor-services-and-standalone-components/latest/managing-vsphere-kuberenetes-service-clusters-and-workloads/installing-standard-packages-on-tkg-service-clusters/installing-standard-packages-on-tkg-cluster-using-tkr-for-vsphere-8-x/installaing-and-using-istio/using-istio/bring-your-own-ca-with-the-istio-package.html

## Preparation Work
```
export CTX_CLUSTER1=vks-ist01:vks-ist01
export CTX_CLUSTER2=vks-ist02:vks-ist02
```

1. Generate shared CA Key/Certificate
```
openssl genrsa -out istio-root-key.pem 4096

openssl req -x509 -new -key istio-root-key.pem -out istio-root-cert.pem -days 3650 \
-subj "/O=vdoubleb.com/CN=Root CA" \
-addext "basicConstraints=critical,CA:TRUE" \
-addext "keyUsage=critical,keyCertSign,cRLSign"
```
```
openssl x509 -in istio-root-cert.pem -text -noout
```
2. Create Package Repository
https://techdocs.broadcom.com/us/en/vmware-cis/vcf/vsphere-supervisor-services-and-standalone-components/latest/managing-vsphere-kuberenetes-service-clusters-and-workloads/installing-standard-packages-on-tkg-service-clusters/installing-standard-packages-on-tkg-cluster-using-tkr-for-vsphere-8-x/create-the-package-repository.html
```
vcf package repository add vks-standard --url projects.packages.broadcom.com/vsphere/supervisor/vks-standard-packages/3.6.0-20260416/vks-standard-packages:3.6.0-20260416 -n tkg-system
 ```
3. Install Cert-Manager
```
vcf package install cert-manager -p  cert-manager.kubernetes.vmware.com -v 1.19.2+vmware.1-vks.1 -n tkg-system
```
4. Create istio-system namespace
```
kubectl create ns istio-system
kubectl label ns istio-system pod-security.kubernetes.io/enforce=privileged
```
5. Create secret for Root CA
```
kubectl create secret tls istio-root-ca --cert=istio-root-cert.pem --key=istio-root-key.pem -n cert-manager
```
6. Create ClusterIssuer
```
kubectl apply -f - <<EOF
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: istio-ca-root
spec:
  ca:
    secretName: istio-root-ca
EOF
```
7. Create Intermediate CA cert for istio
```
kubectl create secret generic cacerts -n istio-system --context=cluster1 \
  --from-file=ca-cert.pem=cluster1-ca-cert.pem \
  --from-file=ca-key.pem=cluster1-ca-key.pem \
  --from-file=root-cert.pem=root-cert.pem \
  --from-file=cert-chain.pem=cluster1-cert-chain.pem
```
OR  
```
kubectl apply -f - <<EOF
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: istio-ca
  namespace: istio-system
spec:
  isCA: true
  commonName: istio-ca
  secretName: cacerts # This creates the secret named 'cacerts'
  duration: 8760h 
  renewBefore: 720h 
  issuerRef:
    name: istio-ca-root
    kind: ClusterIssuer
  # This section instructs cert-manager to format the secret for Istio
  secretTemplate:
    data:
      ca-cert.pem: "{{ .tls.crt }}"
      ca-key.pem: "{{ .tls.key }}"
      root-cert.pem: "{{ .ca.crt }}"
      cert-chain.pem: "{{ .tls.crt }}{{ .ca.crt }}"
EOF
```

## Install Istio on Cluster 1
1. Export data values file
```
vcf package available get istio.kubernetes.vmware.com/1.28.5+vmware.1-vks.1 --default-values-file-output istio-data-values-cluster1.yaml -n tkg-system
```
2. Modify data-values file for Cluster 1
```
 istio:
#   ambientMode:
#   enabled: false
#     ztunnel:
#       resources:
#         limits:
#           cpu: ""
#           memory: ""
#         requests:
#           cpu: 200m
#           memory: 512Mi
#   enableGatewayAPIInference: false
   enableStrictMTLS: true
   gateways:
     egress:
       autoscaling:
         enabled: false
         maxReplicas: 5
         minReplicas: 1
       enabled: true
#       namespace: istio-egress
#       namespaceLimitRange:
#         defaultLimits:
#           cpu: ""
#           memory: ""
#         defaultRequests:
#           cpu: 100m
#           memory: 128Mi
#       priorityClassName: ""
       replicas: 1
#       resources:
#         limits:
#           cpu: 2000m
#           memory: 1024Mi
#         requests:
#           cpu: 100m
#           memory: 128Mi
     ingress:
       autoscaling:
         enabled: false
         maxReplicas: 5
         minReplicas: 1
       enabled: false
#       namespace: istio-ingress
#       namespaceLimitRange:
#         defaultLimits:
#           cpu: ""
#           memory: ""
#         defaultRequests:
#           cpu: 100m
#           memory: 128Mi
#       priorityClassName: ""
#       replicas: 1
#       resources:
#         limits:
#           cpu: 2000m
#           memory: 1024Mi
#         requests:
#           cpu: 100m
#           memory: 128Mi
#   istioCNI:
#     enabled: true
#     resources:
#       limits:
#         cpu: ""
#         memory: ""
#       requests:
#         cpu: 100m
#         memory: 100Mi
   meshConfig:
     accessLogFile: /dev/stdout
     connectTimeout: 10s
     enableDNSProxy: false
     enablePrometheusMerge: true
     enableTracing: true
     externalIstiod: false
     ingressControllerMode: STRICT
     ingressSelector: ingressgateway
     meshID: "mesh01"
     meshMTLS:
       minProtocolVersion: TLSV1_2
     multiCluster:
       clusterName: "vks-ist01"
       clusterProfile: "primary"
       enabled: true
#       remotePilotAddress: ""
     network: "vks-ist01-net"
#     proxy:
#       resources:
#         limits:
#           cpu: 2000m
#           memory: 1024Mi
#         requests:
#           cpu: 100m
#           memory: 128Mi
     trustDomain: cluster.local
#     trustDomainAliases: []
#     waypoint:
#       resources:
#         limits:
#           cpu: "2"
#           memory: 1Gi
#         requests:
#           cpu: 100m
#           memory: 128Mi
   namespace: istio-system
#   namespaceLimitRange:
#     defaultLimits:
#       cpu: ""
#       memory: ""
#     defaultRequests:
#       cpu: 100m
#       memory: 64Mi
#   pilot:
#     autoscaling:
#       enabled: false
#       maxReplicas: 5
#       minReplicas: 2
#     priorityClassName: ""
#     replicas: 2
#     resources:
#       limits:
#         cpu: ""
#         memory: ""
#       requests:
#         cpu: 500m
#         memory: 2048Mi
#   support:
#     priorityClassName: ""
#     resources:
#       limits:
#         cpu: 250m
#         memory: 256Mi
#       requests:
#         cpu: 100m
#         memory: 64Mi
```
3. Install Istio on Primary Cluster
```
vcf package available list -n tkg-system
vcf package available get istio.kubernetes.vmware.com -n tkg-system
vcf package install istio -p istio.kubernetes.vmware.com -v 1.28.5+vmware.1-vks.1 --values-file istio-data-values-cluster1.yaml -n tkg-system
```
4. Create east-west gateway on Cluster 1
```
./eastwest-gw.sh --network vks-ist01-net | istioctl install -y -f -
```
5. Expose Istiod via East-West Gateway
```
apiVersion: networking.istio.io/v1
kind: Gateway
metadata:
  name: istiod-gateway
  namespace: istio-system
spec:
  selector:
    istio: eastwestgateway
  servers:
    - port:
        name: tls-istiod
        number: 15012
        protocol: tls
      tls:
        mode: PASSTHROUGH
      hosts:
        - "*"
    - port:
        name: tls-istiodwebhook
        number: 15017
        protocol: tls
      tls:
        mode: PASSTHROUGH
      hosts:
        - "*"
---
apiVersion: networking.istio.io/v1
kind: VirtualService
metadata:
  name: istiod-vs
  namespace: istio-system
spec:
  hosts:
  - "*"
  gateways:
  - istiod-gateway
  tls:
  - match:
    - port: 15012
      sniHosts:
      - "*"
    route:
    - destination:
        host: istiod.istio-system.svc.cluster.local
        port:
          number: 15012
  - match:
    - port: 15017
      sniHosts:
      - "*"
    route:
    - destination:
        host: istiod.istio-system.svc.cluster.local
        port:
          number: 443
```
## Install Istio on Second Cluster
1. Repeat steps 2-7 in the prerequisites section using the same CA key and pem you generated in step 1.  Multi-cluster istio needs to have a shared CA to establish trust.
2. Copy the istio-data-values-cluster1.yaml to istio-data-values-cluster2.yaml and modify the following fields
```
   meshConfig:
     accessLogFile: /dev/stdout
     connectTimeout: 10s
     enableDNSProxy: false
     enablePrometheusMerge: true
     enableTracing: true
     externalIstiod: false
     ingressControllerMode: STRICT
     ingressSelector: ingressgateway
     meshID: "mesh01"                     # This must match the meshID you used in cluster1
     meshMTLS:
       minProtocolVersion: TLSV1_2
     multiCluster:
       clusterName: "vks-ist02"           # Change to unique name for cluster 2
       clusterProfile: "primary"          # Leave this as primary since we are installing multi-master
       enabled: true
#       remotePilotAddress: ""
     network: "vks-ist02-net"             # Change to unique name for cluster 2
```
3. Install Istio on Cluster2
```
vcf package install istio -p istio.kubernetes.vmware.com -v 1.28.5+vmware.1-vks.1 --values-file istio-data-values-cluster2.yaml -n tkg-system
```
4. Install East-West Gateway on Cluster 2
```
./eastwest-gw.sh --network vks-ist02-net | istioctl install -y -f -

From Gemini (not sure correct)
samples/multicluster/gen-eastwest-gateway.sh \
    --mesh mesh01 --cluster vks-ist02 --network vks-ist01-net > eastwest-gateway.yaml
```
5. Expose Istiod via East-West Gateway
```
apiVersion: networking.istio.io/v1
kind: Gateway
metadata:
  name: istiod-gateway
  namespace: istio-system
spec:
  selector:
    istio: eastwestgateway
  servers:
    - port:
        name: tls-istiod
        number: 15012
        protocol: tls
      tls:
        mode: PASSTHROUGH
      hosts:
        - "*"
    - port:
        name: tls-istiodwebhook
        number: 15017
        protocol: tls
      tls:
        mode: PASSTHROUGH
      hosts:
        - "*"
---
apiVersion: networking.istio.io/v1
kind: VirtualService
metadata:
  name: istiod-vs
  namespace: istio-system
spec:
  hosts:
  - "*"
  gateways:
  - istiod-gateway
  tls:
  - match:
    - port: 15012
      sniHosts:
      - "*"
    route:
    - destination:
        host: istiod.istio-system.svc.cluster.local
        port:
          number: 15012
  - match:
    - port: 15017
      sniHosts:
      - "*"
    route:
    - destination:
        host: istiod.istio-system.svc.cluster.local
        port:
          number: 443
```
## Expose Services on Both Clusters
1. Create cross-network-gateway yaml
```
apiVersion: networking.istio.io/v1
kind: Gateway
metadata:
  name: cross-network-gateway
spec:
  selector:
    istio: eastwestgateway
  servers:
    - port:
        number: 15443
        name: tls
        protocol: TLS
      tls:
        mode: AUTO_PASSTHROUGH
      hosts:
        - "*.local"
```
2. Apply cross-network-gateway on Cluster 1
```
kubectl apply -f cross-network-gateway
```
3. Apply cross-network-gateway on Cluster 2
```
kubectl apply -f cross-network-gateway
```
## Enable Endpoint Discovery

Note Gemini suggest adding label but not sure
```
metadata:
  annotations:
    networking.istio.io/cluster: vks-ist01
  labels:
    istio/multiCluster: "true"
    topology.istio.io/network: vks-ist01-net  # <--- ADD THIS LINE
  name: istio-remote-secret-vks-ist01
  namespace: istio-system
  ```

1. Create the remote secret for cluster 1
```
istioctl create-remote-secret  \
  --name=vks-ist01 
```
2. Create the remote secret for cluster 2
```
istioctl create-remote-secret  \
  --name=vks-ist02 
```
3. Check Sync Status (run from both clusters)
```
istioctl remote-clusters
```

NAME          SECRET                                         STATUS     ISTIOD
vks-ist02                                                    synced     istiod-65b49c5784-96ngm
vks-ist01     istio-system/istio-remote-secret-vks-ist01     synced     istiod-65b49c5784-96ngm
vks-ist02                                                    synced     istiod-65b49c5784-jvmt7
vks-ist01     istio-system/istio-remote-secret-vks-ist01     synced     istiod-65b49c5784-jvmt7

## Test App
1. Create Namespace on both clusters
```
kubectl create --context="${CTX_CLUSTER1}" ns sample
kubectl create --context="${CTX_CLUSTER2}" ns sample
```
2. Enable Istio injection in each namespace
```
kubectl label --context="${CTX_CLUSTER1}" namespace sample \
    istio-injection=enabled
kubectl label --context="${CTX_CLUSTER2}" namespace sample \
    istio-injection=enabled
```
3. Set PSA (optional depending on if PSA is enabled on your cluster.  VKS ships with it on by default)
```
kubectl label --context="${CTX_CLUSTER1}" ns sample \
    pod-security.kubernetes.io/enforce=privileged
kubectl label --context="${CTX_CLUSTER2}" ns sample \
    pod-security.kubernetes.io/enforce=privileged
```
4. Install HelloWorld service in both clusters
```
kubectl apply --context="${CTX_CLUSTER1}" \
    -f https://raw.githubusercontent.com/istio/istio/release-1.28/samples/helloworld/helloworld.yaml \
    -l service=helloworld -n sample
kubectl apply --context="${CTX_CLUSTER2}" \
    -f https://raw.githubusercontent.com/istio/istio/release-1.28/samples/helloworld/helloworld.yaml \
    -l service=helloworld -n sample
```
5. Deploy HelloWorld-v1 application to cluster1
```
kubectl apply --context="${CTX_CLUSTER1}" \
    -f https://raw.githubusercontent.com/istio/istio/release-1.28/samples/helloworld/helloworld.yaml \
    -l version=v1 -n sample
```
6. Deploy Helloworld-v2 to cluster 2
```
kubectl apply --context="${CTX_CLUSTER2}" \
    -f https://raw.githubusercontent.com/istio/istio/release-1.28/samples/helloworld/helloworld.yaml \
    -l version=v2 -n sample
```
7. Deploy Curl appplication to both clusters
```
kubectl apply --context="${CTX_CLUSTER1}" \
    -f https://raw.githubusercontent.com/istio/istio/release-1.28/samples/curl/curl.yaml -n sample
kubectl apply --context="${CTX_CLUSTER2}" \
    -f https://raw.githubusercontent.com/istio/istio/release-1.28/samples/curl/curl.yaml -n sample
```
8. Verify Traffic
```
kubectl exec --context="${CTX_CLUSTER1}" -n sample -c curl \
    "$(kubectl get pod --context="${CTX_CLUSTER1}" -n sample -l \
    app=curl -o jsonpath='{.items[0].metadata.name}')" \
    -- curl -sS helloworld.sample:5000/hello
```

You should see it alternate between v1 and v2 services
```
Hello version: v2, instance: helloworld-v2-758dd55874-6x4t8
Hello version: v1, instance: helloworld-v1-86f77cd7bd-cpxhv
```

## Troubleshooting
1. Check proxy config endpoints
```
istioctl proxy-config endpoints "$(kubectl get pod -l app=curl -n sample -o jsonpath='{.items[0].metadata.name}')" --context="${CTX_CLUSTER1}" -n sample | grep helloworld

192.168.146.9:5000                                      HEALTHY     OK                outbound|5000||helloworld.sample.svc.cluster.local
192.168.147.9:5000                                      HEALTHY     OK                outbound|5000||helloworld.sample.svc.cluster.local

```
2. Check Network Labels between clusters
```
kubectl get cm istio -n istio-system --context="${CTX_CLUSTER1}" -o jsonpath='{.data.mesh}' | grep network
kubectl get cm istio -n istio-system --context="${CTX_CLUSTER2}" -o jsonpath='{.data.mesh}' | grep network
```
3. Verify Pod has mes-network identified
```
kubectl get pod -n sample -l app=helloworld -o jsonpath='{.items[0].metadata.labels}' --context="${CTX_CLUSTER2}"
```

## Install Test App on Primary
1. Enable Istio injection
```
kubectl label ns default istio-injection=enabled
```
2. Set PSA to allowed Priviledged
```
kubectl label ns default pod-security.kubernetes.io/enforce=privileged
```
3. Deploy Google Microservice Test Application
https://github.com/GoogleCloudPlatform/microservices-demo
```
 k apply -f https://raw.githubusercontent.com/GoogleCloudPlatform/microservices-demo/refs/heads/main/release/kubernetes-manifests.yaml
 ```
 4. Deploy Istio Entries for Shop
 ```
 https://raw.githubusercontent.com/GoogleCloudPlatform/microservices-demo/refs/heads/main/release/istio-manifests.yaml
 ```

istioctl proxy-config routes deployment/istio-ingressgateway -n istio-ingress
istioctl proxy-config routes deployment/istio-ingressgateway -n istio-ingress --name http.80 -o json
istioctl analyze -n default
istioctl proxy-config listener deployment/istio-ingressgateway -n istio-ingress --port 80 -o json
istioctl proxy-status
curl -vI http://shop.vdoubleb.com

If using Gateway API instead you can also run
kubectl get httproute frontend-route -n default -o yaml
Look for the status section at the bottom. It should say Accepted: True and Programmed: True.

## Create 443 Gateway for SSL
```
kubectl create secret tls shop-vdoubleb-cert \
  --cert=path/to/cert.crt \
  --key=path/to/cert.key \
  -n istio-ingress
```
```
apiVersion: networking.istio.io/v1beta1
kind: Gateway
metadata:
  name: shared-gateway
  namespace: istio-ingress
spec:
  selector:
    istio: ingressgateway
  servers:
  # HTTP Port 80
  - port:
      number: 80
      name: http
      protocol: HTTP
    hosts:
    - "*/shop.vdoubleb.com"
  
  # HTTPS Port 443
  - port:
      number: 443
      name: https
      protocol: HTTPS
    tls:
      mode: SIMPLE # Standard TLS termination
      credentialName: shop-vdoubleb-cert # Must match the Secret name above
    hosts:
    - "*/shop.vdoubleb.com"
```

1. Gateway CRD for app (or shared) in istio system
2. Virtual Service in app ns

## The Traffic Flow
To visualize how these objects connect, follow the path of a request:

User Request: Hits the External Load Balancer IP.

Istio Ingress Gateway Service: Receives the traffic on a specific port.

Gateway Resource: Validates that the host and port are allowed.

VirtualService: Matches the URL path/headers and decides which internal K8s Service should handle it.

Kubernetes Service: Routes the traffic to the specific Pods (optionally applying rules from a DestinationRule)

1. The Core Istio Objects (The Configuration)
These objects tell the Istio control plane how to handle incoming traffic at the edge of the mesh.

Gateway: Acts as a load balancer at the edge of the mesh. It defines which ports (e.g., 80, 443) and protocols (HTTP, HTTPS, TCP) are open, and which hosts (e.g., api.example.com) are allowed to enter.

VirtualService: This is the most critical object for routing. It links to a Gateway and defines the routing rules. For example, it can say "if the path starts with /v1, send traffic to the v1-service in Kubernetes."

DestinationRule (Optional but Common): While not strictly required for basic exposure, it is used for "post-routing" logic. If you want to perform Canary deployments, configure TLS settings, or set Load Balancing policies (like Random vs. Round Robin), you need a DestinationRule.

Key Differences to Note
GatewayClassName: In your original YAML, you used a selector: istio: ingressgateway. In the Gateway API, Istio watches for Gateways that have gatewayClassName: istio. This automatically manages the deployment and service for the proxy.

Namespace Boundaries: The Gateway API is "secure by default." In your original Istio Gateway, any VirtualService could bind to it. In the new Gateway, you must define allowedRoutes. If you don't include that section, an HTTPRoute in a different namespace will be ignored.

Hostnames: In the HTTPRoute, hostnames is a top-level field, making it much easier to read than the nested hosts list in a VirtualService.

BackendRefs: Instead of destination: host: ..., you use backendRefs. You don't need the full FQDN (.svc.cluster.local) if the service is in the same namespace as the HTTPRoute.

https://oneuptime.com/blog/post/2026-02-24-how-to-manage-ca-certificates-across-multiple-clusters-in-istio/view
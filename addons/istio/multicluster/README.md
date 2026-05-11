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
kubectl apply -f - <<EOF
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: istio-ca
  namespace: istio-system
spec:
  isCA: true
  commonName: istio-ca
  secretName: cacerts
  duration: 8760h  # Update it with a desired duration
  renewBefore: 720h # Update it with a desired time to renew the Certificate.
  issuerRef:
    name: istio-ca-root
    kind: ClusterIssuer
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
   namespace: istio-system
   enableStrictMTLS: true
   gateways:
     egress:
       enabled: true
       replicas: 1
     ingress:
       enabled: false
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
     network: "vks-ist01-net"
     trustDomain: cluster.local
```
3. Install Istio on Primary Cluster
```
vcf package available list -n tkg-system
vcf package available get istio.kubernetes.vmware.com -n tkg-system
vcf package install istio -p istio.kubernetes.vmware.com -v 1.28.5+vmware.1-vks.1 --values-file istio-data-values-cluster1.yaml -n tkg-system
```
4. Create east-west gateway on Cluster 1
```
./eastwest-gw.sh \
   --network vks-ist01-net | \
   istioctl --context="${CTX_CLUSTER1}" install -y -f -
```
5. Expose Istiod via East-West Gateway
```
kubectl apply --context="${CTX_CLUSTER1}" -f - <<EOF
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
EOF
```
6. Create a Cross Network Gateway on Cluster 1
```
kubectl apply --context="${CTX_CLUSTER1}" -f - <<EOF
apiVersion: networking.istio.io/v1
kind: Gateway
metadata:
  name: cross-network-gateway
  namespace: istio-system
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
EOF
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
./eastwest-gw.sh \
   --network vks-ist02-net | \
   istioctl --context="${CTX_CLUSTER2}" install -y -f -
```
5. Expose Istiod via East-West Gateway
```
kubectl apply --context="${CTX_CLUSTER2}" -f - <<EOF
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
EOF
```
## Expose Services on Both Clusters
1. Create cross-network-gateway yaml
```
cat <<EOF > crossnetworkgateway.yaml
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
EOF
```
2. Apply cross-network-gateway on Cluster 1
```
kubectl apply --context="${CTX_CLUSTER1}" -f cross-network-gateway.yaml
```
3. Apply cross-network-gateway on Cluster 2
```
kubectl apply --context="${CTX_CLUSTER2}" -f cross-network-gateway.yaml
```
## Enable Endpoint Discovery

1. Create the remote secret for cluster 1 on cluster 2
```
istioctl create-remote-secret \
  --context="${CTX_CLUSTER1}" \
  --name=vks-ist01 | \
  kubectl apply -f - --context="${CTX_CLUSTER2}"
```
2. Create the remote secret for cluster 2 on cluster 1
```
istioctl create-remote-secret \
  --context="${CTX_CLUSTER2}" \
  --name=vks-ist02 | \
  kubectl apply -f - --context="${CTX_CLUSTER1}"
```
3. Check Sync Status (run from both clusters)
```
istioctl remote-clusters (notice syned status)
```
NAME          SECRET                                         STATUS     ISTIOD
vks-ist01                                                    synced     istiod-54486659f6-4wjjb
vks-ist02     istio-system/istio-remote-secret-vks-ist02     synced     istiod-54486659f6-4wjjb
vks-ist01                                                    synced     istiod-54486659f6-kscsb
vks-ist02     istio-system/istio-remote-secret-vks-ist02     synced     istiod-54486659f6-kscsb

## Test App
1. Create Namespace on both clusters
```
kubectl create --context="${CTX_CLUSTER1}" ns sample
kubectl create --context="${CTX_CLUSTER2}" ns sample
```
2. Enable Istio injection and PSA (may be optional) in each namespace
```
kubectl label namespace sample \
    istio-injection=enabled \
    topology.istio.io/network=vks-ist02-net \
    pod-security.kubernetes.io/enforce=privileged \
    --context="${CTX_CLUSTER1}" --overwrite
kubectl label namespace sample \
    istio-injection=enabled \
    topology.istio.io/network=vks-ist02-net \
    pod-security.kubernetes.io/enforce=privileged \
    --context="${CTX_CLUSTER2}" --overwrite
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
```
# Verify Status
kubectl get pod --context="${CTX_CLUSTER1}" -n sample -l app=helloworld

# Output
NAME                             READY   STATUS    RESTARTS   AGE
helloworld-v1-696f8879d6-kqp26   2/2     Running   0          29s
```
6. Deploy Helloworld-v2 to cluster 2
```
kubectl apply --context="${CTX_CLUSTER2}" \
    -f https://raw.githubusercontent.com/istio/istio/release-1.28/samples/helloworld/helloworld.yaml \
    -l version=v2 -n sample
```
```
# Verify Status
kubectl get pod --context="${CTX_CLUSTER2}" -n sample -l app=helloworld

# Output
NAME                             READY   STATUS    RESTARTS   AGE
helloworld-v2-59fc9f4558-78fbg   2/2     Running   0          76
```
7. Deploy Curl appplication to both clusters
```
kubectl apply --context="${CTX_CLUSTER1}" \
    -f https://raw.githubusercontent.com/istio/istio/release-1.28/samples/curl/curl.yaml -n sample
kubectl apply --context="${CTX_CLUSTER2}" \
    -f https://raw.githubusercontent.com/istio/istio/release-1.28/samples/curl/curl.yaml -n sample
```
```
# Verify Curl Status
kubectl get pod --context="${CTX_CLUSTER1}" -n sample -l app=curl
kubectl get pod --context="${CTX_CLUSTER2}" -n sample -l app=curl
```
8. Verify Traffic
```
kubectl exec --context="${CTX_CLUSTER1}" -n sample -c curl \
    "$(kubectl get pod --context="${CTX_CLUSTER1}" -n sample -l \
    app=curl -o jsonpath='{.items[0].metadata.name}')" \
    -- curl -sS helloworld.sample:5000/hello
```
```
# You should see v1 and v2 alternating but you may need to refresh multiple times
Hello version: v1, instance: helloworld-v1-696f8879d6-kqp26
Hello version: v2, instance: helloworld-v2-59fc9f4558-78fbg
```
```
kubectl exec --context="${CTX_CLUSTER2}" -n sample -c curl \
    "$(kubectl get pod --context="${CTX_CLUSTER2}" -n sample -l \
    app=curl -o jsonpath='{.items[0].metadata.name}')" \
    -- curl -sS helloworld.sample:5000/hello
```
```
# You should see v1 and v2 alternating but you may need to refresh multiple times
Hello version: v1, instance: helloworld-v1-696f8879d6-kqp26
Hello version: v2, instance: helloworld-v2-59fc9f4558-78fbg
```


## Troubleshooting
1. Check proxy config endpoints (note port 5000 instance is local cluster, port 15443 is remote cluster)
```
istioctl proxy-config endpoints "$(kubectl get pod -l app=curl -n sample -o jsonpath='{.items[0].metadata.name}')" - context="${CTX_CLUSTER1}" -n sample | grep helloworld
10.0.116.9:15443                                        HEALTHY     OK                outbound|5000||helloworld.sample.svc.cluster.local
192.168.145.6:5000                                      HEALTHY     OK 
```
2. Check Network Labels between clusters
```
kubectl get cm istio -n istio-system --context="${CTX_CLUSTER1}" -o jsonpath='{.data.mesh}' | grep network
kubectl get cm istio -n istio-system --context="${CTX_CLUSTER2}" -o jsonpath='{.data.mesh}' | grep network
```
3. Verify Pod has mesh-network identified
```
kubectl get pod -n sample -l app=helloworld -o jsonpath='{.items[0].metadata.labels}' --context="${CTX_CLUSTER2}"
```
4. Check Cross-Network-Gateway
```
kubectl get --context="${CTX_CLUSTER1}" gateway.networking.istio.io cross-network-gateway -n istio-system
```
5. Check Listeners
```
istioctl proxy-config listener deployment/istio-eastwestgateway -n istio-system --port 15443 --context="${CTX_CLUSTER2}"
```
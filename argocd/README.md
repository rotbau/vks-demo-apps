# Agrocd on Supervisor and VKS

[Official Docs](https://techdocs.broadcom.com/us/en/vmware-cis/vcf/vsphere-supervisor-services-and-standalone-components/latest/using-supervisor-services/using-argo-cd-service/install-argo-cd-service.html)

## Install ArgoCD Operator on Supervisor

1. Install the Supervisor Service
2. If using vSphere 8 you need to be 8.0u3g or later.  Check /etc/vmware/wcp/supervisor-services-allow-list.txt and verify argo is there

## Install ArgoCD to vsphere namespace (shared services model, differs in VPC)

1. Create a vSphere namespace for Argo through vCenter UI or VCFA
2. Verify which version of Argo is supported through the Operator
```
kubectl explain argocd.spec.version


DESCRIPTION:
    Version specifies the ArgoCD Carvel Package version to deploy.
    The version must follow the pattern: X.Y.Z+vmware.W-vks.V
    Example: "3.0.19+vmware.1-vks.1"
```
3. From the Supervisor Context Install the ArgoCD package using a minimal manifest.  Update the version to match the version returned by the kubect explain command.  Update the instace name and vsphere namespace to match your values.
```
apiVersion: argocd-service.vsphere.vmware.com/v1alpha1
kind: ArgoCD
metadata:
  name: argocd-1
  namespace: argocd-instance-1
spec:
  version: 3.0.19+vmware.1-vks.1
  ```
  ```
  kubectl apply -f argocd-3.0.19.yaml
  argocd.argocd-service.vsphere.vmware.com/argocd-shared created
```
4. Verify the ArgoCD install completed succesfully
```
k get po -n argocd-shared
NAME                                  READY   STATUS      RESTARTS   AGE
argocd-application-controller-0       1/1     Running     0          2m16s
argocd-redis-f58548c96-lnc6q          1/1     Running     0          2m16s
argocd-redis-secret-init-qtgwx        0/1     Completed   0          3m3s
argocd-repo-server-865879ff78-r7f6p   1/1     Running     0          2m16s
argocd-server-7b8f96cc68-7f7f2        1/1     Running     0          2m16s
```
5. Retrieve the service LB IP for argocd server
```
kubectl get svc -n argocd-shared
NAME                 TYPE           CLUSTER-IP    EXTERNAL-IP   PORT(S)                      AGE
argocd-redis         ClusterIP      10.96.0.191   <none>        6379/TCP                     5m
argocd-repo-server   ClusterIP      10.96.0.39    <none>        8081/TCP                     5m
argocd-server        LoadBalancer   10.96.0.209   10.0.104.4    80:32301/TCP,443:32115/TCP   5m
```
6. Retrieve the default ArgoCD admin password
```
kubectl get secret -n argocd-shared argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d
```
7. Use the ArgoCD CLI to authenticate to Argo instance
```
argocd login 10.0.104.4
WARNING: server certificate had error: tls: failed to verify certificate: x509: cannot validate certificate for 172.16.0.206 because it doesn't contain any IP SANs. Proceed insecurely (y/n)? y
Username: admin
Password:
'admin:login' logged in successfully
Context '10.0.104.4' updated
```
8. Update the ArgoCD admin password
```
argocd account update-password
*** Enter password of currently logged in user (admin):
*** Enter new password for user admin:
*** Confirm new password for user admin:
Password updated
```
9. You should now be able to login to the ArgoCD UI using the Load Balancer IP and updated credentials

## Preparing ArgoCD service accounts for Supervisor and vSphere Namespaces

1. Before you can create a VKS cluster, we need to create a Argo service account in the vSphere Namespace where argocd is deployed.  This will allow ArgoCD to provision clusters.  In the example below: 

- 10.0.104.2 is the Supervisor Cluster VIP
- First namespace (argocd-shared) is the vSphere namespace where our Argo is deployed
- Second namespace (test-ns) is the vSphere namespace where we will create clusters
```
argocd cluster add 10.0.104.2 --namespace argocd-shared --namespace test-ns --kubeconfig sc.kubeconfig {optional}
WARNING: This will create a service account `argocd-manager` on the cluster referenced by context `10.0.104.2` with full namespace level privileges. Do you want to continue [y/N]? y

Start permission checking for managing namespace of Supervisor Cluster
{"level":"info","msg":"ServiceAccount \"argocd-manager\" created in namespace \"argocd-shared\"","time":"2026-02-01T17:32:49-06:00"}
{"level":"info","msg":"RoleBinding \"argocd-shared/argocd-shared-argocd-manager-role-binding\" created","time":"2026-02-01T17:32:49-06:00"}
{"level":"info","msg":"RoleBinding \"test-ns/argocd-shared-argocd-manager-role-binding\" created","time":"2026-02-01T17:32:49-06:00"}
{"level":"info","msg":"Created bearer token secret for ServiceAccount \"argocd-manager\"","time":"2026-02-01T17:32:49-06:00"}
Namespace argocd-shared, test-ns from Cluster 'https://10.0.104.2:443' added
```
- You will see 2 secrets created in the `argocd-shared` namespace (argocd-manager-token-l42nk and cluster-10.0.104.2-854864103).
```
NAME                           TYPE                                  DATA   AGE
argocd-initial-admin-secret    Opaque                                1      3h7m
argocd-manager-token-l42nk     kubernetes.io/service-account-token   3      6m46s
argocd-redis                   Opaque                                1      3h8m
argocd-registry-creds          kubernetes.io/dockerconfigjson        1      3h8m
argocd-secret                  Opaque                                5      3h8m
cluster-10.0.104.2-854864103   Opaque                                4      6m46s
```
- If you decode the namespace field of the `cluster-{supervisor vip}-uuid` you can view the vSphere namespaces you are currently able to create clusters in.
```
k get secret cluster-10.0.104.2-854864103 -n argocd-shared -o jsonpath='{.data.namespaces}' | base64 -d

argocd-shared,test-ns
```
2. Add additional vSphere namespaces to Argo.  Use the same command as before and add new namespace test123-ns.  If you don't add existing they will be removed.
```
argocd cluster add 10.0.104.2 --namespace argocd-shared --namespace test-ns --namespace test123-ns --upsert
```

3. Removed Argo Service accounts.  This command doesn't understand the --namespace flag so it completely removes the secrets for Supervisor 10.0.104.2.  If you just want to remove a namespace, run the command in step 2 and omit the namespace you want to remove from the list.  
```
argocd cluster rm 10.0.104.2
```

## Creating a VKS Cluster with ArgoCD

After you've properly configured the service accounts in the vSphere namespace you'd like to create VKS cluster in, you can use the folloiwng commands to create a cluster.  Note ArgoCD only supports vSphere Kubernetes Service 3.3.0 and later.  You can find the examples of full cluster class versioned manifests [in the documentation](https://techdocs.broadcom.com/us/en/vmware-cis/vcf/vsphere-supervisor-services-and-standalone-components/latest/managing-vsphere-kuberenetes-service-clusters-and-workloads/provisioning-tkg-service-clusters/using-the-cluster-v1beta1-api/using-the-versioned-clusterclass.html). Below we are using a minimal VKS 3.4.0 version.

1. Create a github (or similar) structure to store your cluster manifests.  I'm using a very minimal VKS 3.4.0 manifest stored in my github.

2. Use argocd CLI to create an appset that represents the cluster

- `--repo` is your base github repo
- `--path` is the path to the folder containing your cluster yaml files
- `--dest-namespace` is the vSphere namespace where VKS cluster is created
- `--dest-server` is your supervisor cluster added in step 1 of preparing section
- `--sync-policy automated` will automatically begin creating the cluster.  You can omit this flag and then you would need to launch sync automatically.
```
argocd app create vks-test-argo01 --repo https://github.com/rotbau/vks-automation.git --path argocd/cluster-lcm --dest-namespace test-ns --dest-server https://10.0.104.2:443 --sync-policy automated

```
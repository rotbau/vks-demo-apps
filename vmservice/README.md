# VMService Jumpbox

To connect to VKS nodes in an NSX backed environment (segment or vpc) you will need a jumpbox inside the vSphere namespace since VKS nodes are non-routable outside NSX.  There are also some DFW rules between vSphere Namespaces, which is why you may need a jumpbox to be deployed to each.

## VMService Jumpbox Process

1. Download Ubuntu Cloud Image OVA [Example](https://cloud-images.ubuntu.com/noble/current/noble-server-cloudimg-amd64.ova)
2. Create a local content library in vCenter
3. Upload OVA
4. Add VMservice content libray to vSphere namespace
5. Get VM Image Name from vSphere namespace added in step 4
```
# From Supervisor Context

kubectl get vmimage -n test-ns

NAME                    DISPLAY NAME                           
vmi-f86eff0f50f46c724   ubuntu-24.04-server-cloudimg-amd64
```
6. Update the `jumpbox.yaml VirtaulMachine .spec.imageName` with the VM Image name (vmi-eff0f50f46c724) 
 
kind: 
7. Update the `Namespace` for the `PersistentVolumeClaim, ConfigMap, VirtualMachine and VirtualMachineService` sections of the `jumpbox.yaml`
8. Update the jumpbox-cloud-init.yaml with any desired packages or tools
9. Base64 encode the entire jumpbox-cloud-init.yaml file
```
cat jumpbox-cloud-init.yaml |base64 -w 0
```
10. Past the entire base64 string into the `jumpbox.yaml ConfigMap .data.user-data` field.
11. Create the VMService VM from the Supervisor Cluster context
```
kubectl apply -f jumpbox.yaml
```   
12. Verify VM is created and ready
```
kubectl get vm -n test-ns

NAME                                                              POWER-STATE   AGE
jumpbox01                                                         PoweredOn     22h
```
13. Retrive Service IP from VM
```
kubectl get svc -n test-ns

NAME                                  TYPE           CLUSTER-IP    EXTERNAL-IP   PORT(S)          AGE
jumpbox-vmservices                    LoadBalancer   10.96.0.97    10.0.104.9    443/TCP,22/TCP   22h
```
14. You can not connect to the VM using the EXTERNAL-IP on any allowed ports of the VirtualMachineService section of jumpbox.yaml (provided there is something listening on the VM itself).

## VMService to VKS Node

This second option is a little different.  You can just create an external service for SSH to a node and use VM labels to determine which node you go to.

1. Determine labels of VMs that represent the VKS K8s nodes from the vSphere namespace
```
kubectl get vm -n test-ns --show-labels | column -t
```
2. Adjust the vmservice-vks-node-lb.yaml with the correct vSphere namespace and labels avaialbe.  Note you can also custom label a node if you want to get precise targeting.
```
kubectl label vm foo nodename=foo -n test-ns
```
3. Deploy Service in vSphere namespace where VMs reside
```
kubectl apply -f vmservice-vks-node-lb.yaml
```
4. Determine VMService LB IP address
```
kubectl get svc -n test-ns

vks-cluster01-ssh  LoadBalancer   10.96.0.35    10.0.104.10   22/TCP           5s
```
5. SSH to node using vmware-system-user and password from ssh secret in vsphere namespace

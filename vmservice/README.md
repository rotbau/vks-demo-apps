# VMService Jumpbox

To connect to VKS nodes in an NSX backed environment (segment or vpc) you will need a jumpbox inside the vSphere namespace since VKS nodes are non-routable outside NSX.  There are also some DFW rules between vSphere Namespaces, which is why you may need a jumpbox to be deployed to each.

## Process

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
# VKS Cluster Autoscaler Package

Offical documents [located here (https://techdocs.broadcom.com/us/en/vmware-cis/vcf/vsphere-supervisor-services-and-standalone-components/latest/managing-vsphere-kuberenetes-service-clusters-and-workloads/autoscaling-tkg-service-clusters/about-cluster-autoscaling.html)]

Based off upstream cluster autoscaler

- cluster-autoscaler.yaml - example cluster manifest with autoscaler annotations
- package repo - alternative way to create a package repository for offical VKS packages (instead of vcf or tanzu cli)
- autoscaler.yaml - alternative kubectl install of cluster autoscaler VKS package (instead of vcf or tanzu cli)
- app-corrected.yaml - test application you can scale to many replicas to enage cluster autoscaler behavior.
#!/bin/bash

server='https://<supervisor vip or fqdn>'
user='administrator@vsphere.local'

# Can comment these out and use an ENV file to set server and/or username (env example).  You will be prompted for password
kubectl vsphere login --server=$server -u $user --insecure-skip-tls-verify
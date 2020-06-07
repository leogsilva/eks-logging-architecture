#!/bin/bash

kubectl apply -f eks-fluent-bit-configmap.yaml
kubectl apply -f eks-fluent-bit-daemonset-rbac.yaml
kubectl apply -f eks-fluent-bit-daemonset.yaml

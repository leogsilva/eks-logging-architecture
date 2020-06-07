#!/bin/bash

eksctl utils associate-iam-oidc-provider --region=us-east-1 --cluster=basic-cluster --approve

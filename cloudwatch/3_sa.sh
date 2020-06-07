#!/bin/bash

eksctl create iamserviceaccount \
                --name fluentbitds \
                --namespace cw \
		--region us-east-1 \
                --cluster basic-cluster \
                --attach-policy-arn arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy \
                --approve

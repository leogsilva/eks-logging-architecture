arn:aws:iam::721411679615:policy/EKSKinesisFirehosePolicy

# Set Up Fluent Bit as a DaemonSet to Send Logs to CloudWatch

Create a new 1.13 or 1.14 EKS cluster called `container-insights`.

To retrieve image name to use on daemonset

```
aws ssm get-parameters-by-path --path /aws/service/aws-for-fluent-bit/ --query 'Parameters[*].Name'
```

Enable IRSA:

```
eksctl utils associate-iam-oidc-provider \
               --name container-insights \
               --approve
```

Create a namespace:

```
kubectl create ns cw
```

Create SA with `arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy` policy:

```
eksctl create iamserviceaccount \
                --name fluentbitds \
                --namespace cw \
                --cluster container-insights \
                --attach-policy-arn arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy \
                --approve
```

Set up Fluent Bit as DS:

```
kubectl apply -f eks-fluent-bit-configmap.yaml
kubectl apply -f eks-fluent-bit-daemonset-rbac.yaml
kubectl apply -f eks-fluent-bit-daemonset.yaml
```

Set up NGINX for generating logs:

```
kubectl apply -f eks-nginx-app.yaml
```

Verify if all is running:

```
kubectl get po,ds,cm
NAME                       READY   STATUS    RESTARTS   AGE
pod/fluentbit-bkntf        1/1     Running   0          6m11s
pod/nginx-8c5ddb5c-576hm   1/1     Running   0          6m4s

NAME                             DESIRED   CURRENT   READY   UP-TO-DATE   AVAILABLE   NODE SELECTOR   AGE
daemonset.extensions/fluentbit   1         1         1       1            1           <none>          6m12s

NAME                          DATA   AGE
configmap/fluent-bit-config   2      6m32s
```

Generate load on NGINX to produce logs, for example using `kubectl port-forward service/nginx 9090:80` and then `curl localhost:9090`.


# Creating the Athena objects

First, we create a database
```
CREATE DATABASE IF NOT EXISTS eks_log
  LOCATION 's3://mybucket/2020'
```

The pattern used on fluentbit is the following
```
^(?<timestamp>[0-9]{2,4}\-[0-9]{1,2}\-[0-9]{1,2} [0-9]{1,2}\:[0-9]{1,2}\:[0-9]{1,2}\,\d{1,6}) (?<level>[^ ]*\s{0,2}) \[(?<component>[^\]]*)\] (?<message>.*)
```


So we need to create a table that reflects this structure:

```
CREATE EXTERNAL TABLE fluentbit_apps (
         timestamp string,
         level string,
         component string,
         message string
) 
ROW FORMAT SERDE 'org.openx.data.jsonserde.JsonSerDe' 
LOCATION 's3://mybucket/2020/'
```

Then, just selects data from the table

```
select * from fluentbit_apps
```
\# CloudMart E-commerce Platform - Step-by-Step Commands

\## Complete Deployment Guide



This guide provides individual commands to deploy the CloudMart platform step-by-step.



\*\*Total Time\*\*: ~25-30 minutes  

\*\*Project ID\*\*: `playground-s-11-60fe91d0`  

\*\*Region\*\*: `us-central1`



---



\## Prerequisites



Before starting, ensure you have:

\- Google Cloud Shell open OR gcloud CLI installed locally

\- kubectl installed

\- Access to GCP project: `playground-s-11-60fe91d0`



---



\## Phase 1: Project Setup (2 minutes)



\### Step 1: Configure Project

```bash

gcloud config set project playground-s-11-60fe91d0

gcloud config set compute/region us-central1

gcloud config set compute/zone us-central1-a

```



Show configured project settings



---



\### Step 2: Enable Required APIs

```bash

gcloud services enable \\

&nbsp;   container.googleapis.com \\

&nbsp;   sqladmin.googleapis.com \\

&nbsp;   redis.googleapis.com \\

&nbsp;   storage-api.googleapis.com \\

&nbsp;   compute.googleapis.com \\

&nbsp;   servicenetworking.googleapis.com \\

&nbsp;   monitoring.googleapis.com \\

&nbsp;   logging.googleapis.com

```



Navigate to \*\*APIs \& Services\*\* → \*\*Enabled APIs\*\* and capture



---



\## Phase 2: Network Infrastructure (5 minutes)



\### Step 3: Create VPC Network

```bash

gcloud compute networks create cloudmart-vpc \\

&nbsp;   --subnet-mode=custom \\

&nbsp;   --bgp-routing-mode=regional

```



\*\*VPC Network\*\* → \*\*VPC networks\*\* → Show `cloudmart-vpc`



---



\### Step 4: Create Subnet with Secondary Ranges

```bash

gcloud compute networks subnets create cloudmart-subnet \\

&nbsp;   --network=cloudmart-vpc \\

&nbsp;   --region=us-central1 \\

&nbsp;   --range=10.0.0.0/20 \\

&nbsp;   --secondary-range=pods=10.4.0.0/14 \\

&nbsp;   --secondary-range=services=10.0.16.0/20 \\

&nbsp;   --enable-private-ip-google-access

```



\*\*Key Parameters\*\*:

\- `--range=10.0.0.0/20`: Primary subnet (4,096 IPs for nodes)

\- `--secondary-range=pods`: Pod IP range (262,144 IPs)

\- `--secondary-range=services`: Service IP range (4,096 IPs)



\*\*Screenshot 4\*\*: \*\*VPC Network\*\* → \*\*VPC networks\*\* → `cloudmart-vpc` → \*\*Subnets\*\* → Show secondary ranges



---



\### Step 5: Create Firewall Rules



Allow internal communication:

```bash

gcloud compute firewall-rules create cloudmart-allow-internal \\

&nbsp;   --network=cloudmart-vpc \\

&nbsp;   --allow=tcp,udp,icmp \\

&nbsp;   --source-ranges=10.0.0.0/20,10.4.0.0/14,10.0.16.0/20

```



Allow load balancer health checks:

```bash

gcloud compute firewall-rules create cloudmart-allow-lb-health-checks \\

&nbsp;   --network=cloudmart-vpc \\

&nbsp;   --allow=tcp \\

&nbsp;   --source-ranges=35.191.0.0/16,130.211.0.0/22 \\

&nbsp;   --target-tags=gke-node

```



\*\*Screenshot 5\*\*: \*\*VPC Network\*\* → \*\*Firewall\*\* → Show both rules



---



\## Phase 3: GKE Cluster (10 minutes)



\### Step 6: Create GKE Cluster

```bash

gcloud container clusters create cloudmart-cluster \\

&nbsp;   --region=us-central1 \\

&nbsp;   --network=cloudmart-vpc \\

&nbsp;   --subnetwork=cloudmart-subnet \\

&nbsp;   --cluster-secondary-range-name=pods \\

&nbsp;   --services-secondary-range-name=services \\

&nbsp;   --num-nodes=1 \\

&nbsp;   --machine-type=e2-medium \\

&nbsp;   --disk-size=20 \\

&nbsp;   --enable-autoscaling \\

&nbsp;   --min-nodes=1 \\

&nbsp;   --max-nodes=2 \\

&nbsp;   --enable-ip-alias \\

&nbsp;   --enable-autorepair \\

&nbsp;   --enable-autoupgrade \\

&nbsp;   --addons=HorizontalPodAutoscaling,HttpLoadBalancing

```



\*\*This takes 8-10 minutes\*\*



\*\*Screenshot 6\*\*: \*\*Kubernetes Engine\*\* → \*\*Clusters\*\* → Show cluster creating/running



---



\### Step 7: Configure kubectl

```bash

gcloud container clusters get-credentials cloudmart-cluster --region=us-central1

```



Verify nodes:

```bash

kubectl get nodes

```



\*\*Screenshot 7\*\*: Terminal showing 3 nodes in Ready state



---



\### Step 8: View Node Details

```bash

kubectl get nodes -o wide

```



\*\*Screenshot 8\*\*: \*\*Kubernetes Engine\*\* → \*\*Clusters\*\* → `cloudmart-cluster` → \*\*Nodes\*\* tab



---



\## Phase 4: Database (Cloud SQL) (12 minutes)



\### Step 9: Setup VPC Peering for Cloud SQL



Create IP address range:

```bash

gcloud compute addresses create google-managed-services-cloudmart \\

&nbsp;   --global \\

&nbsp;   --purpose=VPC\_PEERING \\

&nbsp;   --prefix-length=16 \\

&nbsp;   --network=cloudmart-vpc

```



Connect VPC peering:

```bash

gcloud services vpc-peerings connect \\

&nbsp;   --service=servicenetworking.googleapis.com \\

&nbsp;   --ranges=google-managed-services-cloudmart \\

&nbsp;   --network=cloudmart-vpc

```



---



\### Step 10: Create Cloud SQL Instance

```bash

gcloud sql instances create cloudmart-db \\

&nbsp;   --database-version=POSTGRES\_15 \\

&nbsp;   --tier=db-f1-micro \\

&nbsp;   --region=us-central1 \\

&nbsp;   --network=projects/playground-s-11-60fe91d0/global/networks/cloudmart-vpc \\

&nbsp;   --no-assign-ip \\

&nbsp;   --root-password=CloudMart2024!

```



\*\*This takes 10-12 minutes\*\*



\*\*Screenshot 9\*\*: \*\*SQL\*\* → \*\*Instances\*\* → Show `cloudmart-db` creating/running



---



\### Step 11: Create Databases

```bash

gcloud sql databases create products --instance=cloudmart-db

gcloud sql databases create orders --instance=cloudmart-db

gcloud sql databases create users --instance=cloudmart-db

```



Verify:

```bash

gcloud sql databases list --instance=cloudmart-db

```



\*\*Screenshot 10\*\*: \*\*SQL\*\* → \*\*Instances\*\* → `cloudmart-db` → \*\*Databases\*\* tab



---



\### Step 12: Create Application User

```bash

gcloud sql users create cloudmart \\

&nbsp;   --instance=cloudmart-db \\

&nbsp;   --password=CloudMart2024AppUser!

```



---



\### Step 13: Get Cloud SQL Private IP

```bash

gcloud sql instances describe cloudmart-db \\

&nbsp;   --format="value(ipAddresses\[0].ipAddress)"

```



\*\*Save this IP\*\*: You'll need it for application configuration



\*\*Screenshot 11\*\*: \*\*SQL\*\* → \*\*Instances\*\* → `cloudmart-db` → \*\*Connections\*\* → Show private IP



---



\## Phase 5: Cache (Memorystore Redis) (5 minutes)



\### Step 14: Create Redis Instance

```bash

gcloud redis instances create cloudmart-cache \\

&nbsp;   --size=1 \\

&nbsp;   --region=us-central1 \\

&nbsp;   --network=projects/playground-s-11-60fe91d0/global/networks/cloudmart-vpc \\

&nbsp;   --redis-version=redis\_7\_0 \\

&nbsp;   --tier=basic

```



\*\*This takes 3-5 minutes\*\*



\*\*Screenshot 12\*\*: \*\*Memorystore\*\* → \*\*Redis\*\* → Show `cloudmart-cache` creating/running



---



\### Step 15: Get Redis Connection Details

```bash

gcloud redis instances describe cloudmart-cache --region=us-central1 \\

&nbsp;   --format="value(host,port)"

```



\*\*Save these values\*\*: Host IP and port 6379



\*\*Screenshot 13\*\*: \*\*Memorystore\*\* → \*\*Redis\*\* → `cloudmart-cache` → Show connection info



---



\## Phase 6: Storage (Cloud Storage) (1 minute)



\### Step 16: Create Storage Buckets



Images bucket:

```bash

gsutil mb -p playground-s-11-60fe91d0 -c STANDARD -l us-central1 \\

&nbsp;   gs://playground-s-11-60fe91d0-images/

```



Static assets bucket:

```bash

gsutil mb -p playground-s-11-60fe91d0 -c STANDARD -l us-central1 \\

&nbsp;   gs://playground-s-11-60fe91d0-static/

```



Receipts bucket:

```bash

gsutil mb -p playground-s-11-60fe91d0 -c STANDARD -l us-central1 \\

&nbsp;   gs://playground-s-11-60fe91d0-receipts/

```



Verify:

```bash

gsutil ls

```



\*\*Screenshot 14\*\*: \*\*Cloud Storage\*\* → \*\*Buckets\*\* → Show all 3 buckets



---



\## Phase 7: Deploy Test Application (3 minutes)



\### Step 17: Create Kubernetes Namespace

```bash

kubectl create namespace cloudmart

```



Verify:

```bash

kubectl get namespaces

```



---



\### Step 18: Deploy Test Application

```bash

kubectl create deployment test-app \\

&nbsp;   --image=nginx:latest \\

&nbsp;   --replicas=2 \\

&nbsp;   -n cloudmart

```



Check deployment:

```bash

kubectl get deployments -n cloudmart

kubectl get pods -n cloudmart

```



\*\*Screenshot 15\*\*: Terminal showing 2 pods running



---



\### Step 19: Expose Application with Load Balancer

```bash

kubectl expose deployment test-app \\

&nbsp;   --type=LoadBalancer \\

&nbsp;   --port=80 \\

&nbsp;   --target-port=80 \\

&nbsp;   -n cloudmart

```



---



\### Step 20: Get Load Balancer External IP

```bash

kubectl get service test-app -n cloudmart

```



\*\*Wait 2-3 minutes for external IP\*\* (initially shows `<pending>`)



Keep running the command until you see an IP address.



\*\*Screenshot 16\*\*: Terminal showing service with EXTERNAL-IP



---



\### Step 21: Test the Application

```bash

\# Replace with your actual external IP

curl http://EXTERNAL\_IP

```



You should see the nginx welcome page HTML.



\*\*Screenshot 17\*\*: Terminal showing successful curl response



---



\## Phase 8: Configure Auto-Scaling (1 minute)



\### Step 22: Create Horizontal Pod Autoscaler

```bash

kubectl autoscale deployment test-app \\

&nbsp;   --cpu-percent=50 \\

&nbsp;   --min=2 \\

&nbsp;   --max=5 \\

&nbsp;   -n cloudmart

```



Check HPA:

```bash

kubectl get hpa -n cloudmart

```



\*\*Screenshot 18\*\*: Terminal showing HPA configured



---



\## Phase 9: Chaos Engineering Tests (5 minutes)



\### Test 1: Pod Auto-Healing



Watch pods:

```bash

kubectl get pods -n cloudmart -w

```



In another terminal, delete a pod:

```bash

POD=$(kubectl get pods -n cloudmart -o jsonpath='{.items\[0].metadata.name}')

kubectl delete pod $POD -n cloudmart

```



\*\*Observe\*\*: Pod terminates, new pod automatically created in ~1 second



\*\*Screenshot 19\*\*: Terminal showing pod deletion and auto-creation



Press Ctrl+C to stop watching.



---



\### Test 2: Bad Deployment Rollback



Check current status:

```bash

kubectl rollout status deployment/test-app -n cloudmart

```



Deploy broken image:

```bash

kubectl set image deployment/test-app \\

&nbsp;   nginx=nginx:broken \\

&nbsp;   -n cloudmart

```



Watch pods (you'll see ImagePullBackOff):

```bash

kubectl get pods -n cloudmart

```



\*\*Screenshot 20\*\*: Terminal showing failed pod with ImagePullBackOff



Rollback:

```bash

kubectl rollout undo deployment/test-app -n cloudmart

```



Verify recovery:

```bash

kubectl rollout status deployment/test-app -n cloudmart

kubectl get pods -n cloudmart

```



\*\*Screenshot 21\*\*: Terminal showing successful rollback, all pods running



---



\## Phase 10: Monitoring \& Observability (2 minutes)



\### Step 23: View Cluster in Console



\*\*Screenshot 22\*\*: \*\*Kubernetes Engine\*\* → \*\*Clusters\*\* → `cloudmart-cluster` → \*\*Overview\*\*



---



\### Step 24: View Workloads



\*\*Screenshot 23\*\*: \*\*Kubernetes Engine\*\* → \*\*Workloads\*\* → Show `test-app` deployment



---



\### Step 25: View Services



\*\*Screenshot 24\*\*: \*\*Kubernetes Engine\*\* → \*\*Services \& Ingress\*\* → Show `test-app` service with external IP



---



\## Final Summary



\### Infrastructure Deployed



Run these commands to get all details:

```bash

echo "=== GKE Cluster ==="

kubectl get nodes



echo ""

echo "=== Cloud SQL ==="

gcloud sql instances describe cloudmart-db \\

&nbsp;   --format="value(name,databaseVersion,settings.tier,ipAddresses\[0].ipAddress)"



echo ""

echo "=== Memorystore Redis ==="

gcloud redis instances describe cloudmart-cache --region=us-central1 \\

&nbsp;   --format="value(name,tier,memorySizeGb,host,port)"



echo ""

echo "=== Storage Buckets ==="

gsutil ls



echo ""

echo "=== Load Balancer ==="

kubectl get svc test-app -n cloudmart

```



\*\*Screenshot 25\*\*: Terminal showing complete infrastructure summary



---



\## Cost Summary



Estimated monthly cost: \*\*~$149\*\*



| Component | Monthly Cost |

|-----------|--------------|

| GKE (3 × e2-medium) | $73 |

| Cloud SQL (db-f1-micro) | $8 |

| Memorystore (1GB Redis) | $38 |

| Cloud Storage (100GB) | $2 |

| Load Balancer | $18 |

| Monitoring/Logging | $10 |



---



\## Cleanup Commands



When finished, delete all resources:

```bash

\# Delete test application

kubectl delete namespace cloudmart



\# Delete Redis

gcloud redis instances delete cloudmart-cache --region=us-central1 --quiet



\# Delete Cloud SQL

gcloud sql instances delete cloudmart-db --quiet



\# Delete GKE cluster

gcloud container clusters delete cloudmart-cluster --region=us-central1 --quiet



\# Delete VPC peering

gcloud services vpc-peerings delete \\

&nbsp;   --service=servicenetworking.googleapis.com \\

&nbsp;   --network=cloudmart-vpc --quiet



\# Delete IP range

gcloud compute addresses delete google-managed-services-cloudmart --global --quiet



\# Delete buckets

gsutil -m rm -r gs://playground-s-11-60fe91d0-images/

gsutil -m rm -r gs://playground-s-11-60fe91d0-static/

gsutil -m rm -r gs://playground-s-11-60fe91d0-receipts/



\# Delete firewall rules

gcloud compute firewall-rules delete cloudmart-allow-internal --quiet

gcloud compute firewall-rules delete cloudmart-allow-lb-health-checks --quiet



\# Delete subnet

gcloud compute networks subnets delete cloudmart-subnet --region=us-central1 --quiet



\# Delete VPC

gcloud compute networks delete cloudmart-vpc --quiet

```



---



\## Screenshot Checklist



\- \[ ] 1. Project configuration

\- \[ ] 2. Enabled APIs

\- \[ ] 3. VPC network created

\- \[ ] 4. Subnet with secondary ranges

\- \[ ] 5. Firewall rules

\- \[ ] 6. GKE cluster overview

\- \[ ] 7. Nodes in terminal (kubectl get nodes)

\- \[ ] 8. Nodes in console

\- \[ ] 9. Cloud SQL instance

\- \[ ] 10. Cloud SQL databases

\- \[ ] 11. Cloud SQL private IP

\- \[ ] 12. Memorystore Redis instance

\- \[ ] 13. Redis connection details

\- \[ ] 14. Storage buckets

\- \[ ] 15. Pods running (kubectl get pods)

\- \[ ] 16. Service with external IP

\- \[ ] 17. Successful curl test

\- \[ ] 18. HPA configured

\- \[ ] 19. Pod auto-healing demo

\- \[ ] 20. Failed deployment (ImagePullBackOff)

\- \[ ] 21. Successful rollback

\- \[ ] 22. Cluster overview in console

\- \[ ] 23. Workloads view

\- \[ ] 24. Services view

\- \[ ] 25. Final infrastructure summary



---



\## Skills Demonstrated



\- Google Kubernetes Engine (GKE) cluster management

\- Cloud SQL database deployment and configuration

\- Memorystore Redis caching layer

\- VPC networking with custom subnets and secondary IP ranges

\- Firewall rule configuration for security

\- Kubernetes deployments and services

\- Load balancer configuration

\- Horizontal Pod Autoscaling (HPA)

\- Chaos engineering (pod deletion, rollback testing)

\- Infrastructure as Code with gcloud CLI

\- Site Reliability Engineering principles

\- Zero-downtime deployments

\- Cost analysis and optimization



---



\*\*Deployment Time\*\*: ~25-30 minutes  

\*\*Skill Level\*\*: Intermediate to Advanced  

\*\*Certification Alignment\*\*: Google Cloud Professional Cloud Architect


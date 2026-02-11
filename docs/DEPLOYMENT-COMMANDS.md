# CloudMart E-commerce Platform - Step-by-Step Commands
## Complete Deployment Guide

This guide provides individual commands to deploy the CloudMart platform step-by-step.

**Total Time**: ~25-30 minutes  
**Project ID**: `playground-s-11-60fe91d0`  
**Region**: `us-central1`

---

## Prerequisites

Before starting, ensure you have:
- Google Cloud Shell open OR gcloud CLI installed locally
- kubectl installed
- Access to GCP project: `playground-s-11-60fe91d0`

---

## Phase 1: Project Setup (2 minutes)

### Step 1: Configure Project
```bash
gcloud config set project playground-s-11-60fe91d0
gcloud config set compute/region us-central1
gcloud config set compute/zone us-central1-a
```

**Checkpoint 1**: Verify project configuration

---

### Step 2: Enable Required APIs
```bash
gcloud services enable \
    container.googleapis.com \
    sqladmin.googleapis.com \
    redis.googleapis.com \
    storage-api.googleapis.com \
    compute.googleapis.com \
    servicenetworking.googleapis.com \
    monitoring.googleapis.com \
    logging.googleapis.com
```

**Checkpoint 2**: Navigate to **APIs & Services** → **Enabled APIs** to verify

---

## Phase 2: Network Infrastructure (5 minutes)

### Step 3: Create VPC Network
```bash
gcloud compute networks create cloudmart-vpc \
    --subnet-mode=custom \
    --bgp-routing-mode=regional
```

**Checkpoint 3**: **VPC Network** → **VPC networks** → Verify `cloudmart-vpc`

---

### Step 4: Create Subnet with Secondary Ranges
```bash
gcloud compute networks subnets create cloudmart-subnet \
    --network=cloudmart-vpc \
    --region=us-central1 \
    --range=10.0.0.0/20 \
    --secondary-range=pods=10.4.0.0/14 \
    --secondary-range=services=10.0.16.0/20 \
    --enable-private-ip-google-access
```

**Key Parameters**:
- `--range=10.0.0.0/20`: Primary subnet (4,096 IPs for nodes)
- `--secondary-range=pods`: Pod IP range (262,144 IPs)
- `--secondary-range=services`: Service IP range (4,096 IPs)

**Checkpoint 4**: **VPC Network** → **VPC networks** → `cloudmart-vpc` → **Subnets** → Verify secondary ranges

---

### Step 5: Create Firewall Rules

Allow internal communication:
```bash
gcloud compute firewall-rules create cloudmart-allow-internal \
    --network=cloudmart-vpc \
    --allow=tcp,udp,icmp \
    --source-ranges=10.0.0.0/20,10.4.0.0/14,10.0.16.0/20
```

Allow load balancer health checks:
```bash
gcloud compute firewall-rules create cloudmart-allow-lb-health-checks \
    --network=cloudmart-vpc \
    --allow=tcp \
    --source-ranges=35.191.0.0/16,130.211.0.0/22 \
    --target-tags=gke-node
```

**Checkpoint 5**: **VPC Network** → **Firewall** → Verify both rules

---

## Phase 3: GKE Cluster (10 minutes)

### Step 6: Create GKE Cluster
```bash
gcloud container clusters create cloudmart-cluster \
    --region=us-central1 \
    --network=cloudmart-vpc \
    --subnetwork=cloudmart-subnet \
    --cluster-secondary-range-name=pods \
    --services-secondary-range-name=services \
    --num-nodes=1 \
    --machine-type=e2-medium \
    --disk-size=20 \
    --enable-autoscaling \
    --min-nodes=1 \
    --max-nodes=2 \
    --enable-ip-alias \
    --enable-autorepair \
    --enable-autoupgrade \
    --addons=HorizontalPodAutoscaling,HttpLoadBalancing
```

**This takes 8-10 minutes**

**Checkpoint 6**: **Kubernetes Engine** → **Clusters** → Verify cluster status

---

### Step 7: Configure kubectl
```bash
gcloud container clusters get-credentials cloudmart-cluster --region=us-central1
```

Verify nodes:
```bash
kubectl get nodes
```

**Checkpoint 7**: Terminal showing 3 nodes in Ready state

---

### Step 8: View Node Details
```bash
kubectl get nodes -o wide
```

**Checkpoint 8**: **Kubernetes Engine** → **Clusters** → `cloudmart-cluster` → **Nodes** tab

---

## Phase 4: Database (Cloud SQL) (12 minutes)

### Step 9: Setup VPC Peering for Cloud SQL

Create IP address range:
```bash
gcloud compute addresses create google-managed-services-cloudmart \
    --global \
    --purpose=VPC_PEERING \
    --prefix-length=16 \
    --network=cloudmart-vpc
```

Connect VPC peering:
```bash
gcloud services vpc-peerings connect \
    --service=servicenetworking.googleapis.com \
    --ranges=google-managed-services-cloudmart \
    --network=cloudmart-vpc
```

---

### Step 10: Create Cloud SQL Instance
```bash
gcloud sql instances create cloudmart-db \
    --database-version=POSTGRES_15 \
    --tier=db-f1-micro \
    --region=us-central1 \
    --network=projects/playground-s-11-60fe91d0/global/networks/cloudmart-vpc \
    --no-assign-ip \
    --root-password=CloudMart2024!
```

**This takes 10-12 minutes**

**Checkpoint 9**: **SQL** → **Instances** → Verify `cloudmart-db` status

---

### Step 11: Create Databases
```bash
gcloud sql databases create products --instance=cloudmart-db
gcloud sql databases create orders --instance=cloudmart-db
gcloud sql databases create users --instance=cloudmart-db
```

Verify:
```bash
gcloud sql databases list --instance=cloudmart-db
```

**Checkpoint 10**: **SQL** → **Instances** → `cloudmart-db` → **Databases** tab

---

### Step 12: Create Application User
```bash
gcloud sql users create cloudmart \
    --instance=cloudmart-db \
    --password=CloudMart2024AppUser!
```

---

### Step 13: Get Cloud SQL Private IP
```bash
gcloud sql instances describe cloudmart-db \
    --format="value(ipAddresses[0].ipAddress)"
```

**Save this IP**: You'll need it for application configuration

**Checkpoint 11**: **SQL** → **Instances** → `cloudmart-db` → **Connections** → Note private IP

---

## Phase 5: Cache (Memorystore Redis) (5 minutes)

### Step 14: Create Redis Instance
```bash
gcloud redis instances create cloudmart-cache \
    --size=1 \
    --region=us-central1 \
    --network=projects/playground-s-11-60fe91d0/global/networks/cloudmart-vpc \
    --redis-version=redis_7_0 \
    --tier=basic
```

**This takes 3-5 minutes**

**Checkpoint 12**: **Memorystore** → **Redis** → Verify `cloudmart-cache` status

---

### Step 15: Get Redis Connection Details
```bash
gcloud redis instances describe cloudmart-cache --region=us-central1 \
    --format="value(host,port)"
```

**Save these values**: Host IP and port 6379

**Checkpoint 13**: **Memorystore** → **Redis** → `cloudmart-cache` → Note connection info

---

## Phase 6: Storage (Cloud Storage) (1 minute)

### Step 16: Create Storage Buckets

Images bucket:
```bash
gsutil mb -p playground-s-11-60fe91d0 -c STANDARD -l us-central1 \
    gs://playground-s-11-60fe91d0-images/
```

Static assets bucket:
```bash
gsutil mb -p playground-s-11-60fe91d0 -c STANDARD -l us-central1 \
    gs://playground-s-11-60fe91d0-static/
```

Receipts bucket:
```bash
gsutil mb -p playground-s-11-60fe91d0 -c STANDARD -l us-central1 \
    gs://playground-s-11-60fe91d0-receipts/
```

Verify:
```bash
gsutil ls
```

**Checkpoint 14**: **Cloud Storage** → **Buckets** → Verify all 3 buckets

---

## Phase 7: Deploy Test Application (3 minutes)

### Step 17: Create Kubernetes Namespace
```bash
kubectl create namespace cloudmart
```

Verify:
```bash
kubectl get namespaces
```

---

### Step 18: Deploy Test Application
```bash
kubectl create deployment test-app \
    --image=nginx:latest \
    --replicas=2 \
    -n cloudmart
```

Check deployment:
```bash
kubectl get deployments -n cloudmart
kubectl get pods -n cloudmart
```

**Checkpoint 15**: Terminal showing 2 pods running

---

### Step 19: Expose Application with Load Balancer
```bash
kubectl expose deployment test-app \
    --type=LoadBalancer \
    --port=80 \
    --target-port=80 \
    -n cloudmart
```

---

### Step 20: Get Load Balancer External IP
```bash
kubectl get service test-app -n cloudmart
```

**Wait 2-3 minutes for external IP** (initially shows `<pending>`)

Keep running the command until you see an IP address.

**Checkpoint 16**: Terminal showing service with EXTERNAL-IP

---

### Step 21: Test the Application
```bash
# Replace with your actual external IP
curl http://EXTERNAL_IP
```

You should see the nginx welcome page HTML.

**Checkpoint 17**: Terminal showing successful curl response

---

## Phase 8: Configure Auto-Scaling (1 minute)

### Step 22: Create Horizontal Pod Autoscaler
```bash
kubectl autoscale deployment test-app \
    --cpu-percent=50 \
    --min=2 \
    --max=5 \
    -n cloudmart
```

Check HPA:
```bash
kubectl get hpa -n cloudmart
```

**Checkpoint 18**: Terminal showing HPA configured

---

## Phase 9: Chaos Engineering Tests (5 minutes)

### Test 1: Pod Auto-Healing

Watch pods:
```bash
kubectl get pods -n cloudmart -w
```

In another terminal, delete a pod:
```bash
POD=$(kubectl get pods -n cloudmart -o jsonpath='{.items[0].metadata.name}')
kubectl delete pod $POD -n cloudmart
```

**Observe**: Pod terminates, new pod automatically created in ~1 second

**Checkpoint 19**: Terminal showing pod deletion and auto-creation

Press Ctrl+C to stop watching.

---

### Test 2: Bad Deployment Rollback

Check current status:
```bash
kubectl rollout status deployment/test-app -n cloudmart
```

Deploy broken image:
```bash
kubectl set image deployment/test-app \
    nginx=nginx:broken \
    -n cloudmart
```

Watch pods (you'll see ImagePullBackOff):
```bash
kubectl get pods -n cloudmart
```

**Checkpoint 20**: Terminal showing failed pod with ImagePullBackOff

Rollback:
```bash
kubectl rollout undo deployment/test-app -n cloudmart
```

Verify recovery:
```bash
kubectl rollout status deployment/test-app -n cloudmart
kubectl get pods -n cloudmart
```

**Checkpoint 21**: Terminal showing successful rollback, all pods running

---

## Phase 10: Monitoring & Observability (2 minutes)

### Step 23: View Cluster in Console

**Checkpoint 22**: **Kubernetes Engine** → **Clusters** → `cloudmart-cluster` → **Overview**

---

### Step 24: View Workloads

**Checkpoint 23**: **Kubernetes Engine** → **Workloads** → Verify `test-app` deployment

---

### Step 25: View Services

**Checkpoint 24**: **Kubernetes Engine** → **Services & Ingress** → Verify `test-app` service with external IP

---

## Final Summary

### Infrastructure Deployed

Run these commands to get all details:
```bash
echo "=== GKE Cluster ==="
kubectl get nodes

echo ""
echo "=== Cloud SQL ==="
gcloud sql instances describe cloudmart-db \
    --format="value(name,databaseVersion,settings.tier,ipAddresses[0].ipAddress)"

echo ""
echo "=== Memorystore Redis ==="
gcloud redis instances describe cloudmart-cache --region=us-central1 \
    --format="value(name,tier,memorySizeGb,host,port)"

echo ""
echo "=== Storage Buckets ==="
gsutil ls

echo ""
echo "=== Load Balancer ==="
kubectl get svc test-app -n cloudmart
```

**Checkpoint 25**: Terminal showing complete infrastructure summary

---

## Cost Summary

Estimated monthly cost: **~$149**

| Component | Monthly Cost |
|-----------|--------------|
| GKE (3 × e2-medium) | $73 |
| Cloud SQL (db-f1-micro) | $8 |
| Memorystore (1GB Redis) | $38 |
| Cloud Storage (100GB) | $2 |
| Load Balancer | $18 |
| Monitoring/Logging | $10 |

---

## Cleanup Commands

When finished, delete all resources:
```bash
# Delete test application
kubectl delete namespace cloudmart

# Delete Redis
gcloud redis instances delete cloudmart-cache --region=us-central1 --quiet

# Delete Cloud SQL
gcloud sql instances delete cloudmart-db --quiet

# Delete GKE cluster
gcloud container clusters delete cloudmart-cluster --region=us-central1 --quiet

# Delete VPC peering
gcloud services vpc-peerings delete \
    --service=servicenetworking.googleapis.com \
    --network=cloudmart-vpc --quiet

# Delete IP range
gcloud compute addresses delete google-managed-services-cloudmart --global --quiet

# Delete buckets
gsutil -m rm -r gs://playground-s-11-60fe91d0-images/
gsutil -m rm -r gs://playground-s-11-60fe91d0-static/
gsutil -m rm -r gs://playground-s-11-60fe91d0-receipts/

# Delete firewall rules
gcloud compute firewall-rules delete cloudmart-allow-internal --quiet
gcloud compute firewall-rules delete cloudmart-allow-lb-health-checks --quiet

# Delete subnet
gcloud compute networks subnets delete cloudmart-subnet --region=us-central1 --quiet

# Delete VPC
gcloud compute networks delete cloudmart-vpc --quiet
```

---

## Deployment Checklist

- [ ] 1. Project configuration
- [ ] 2. Enabled APIs
- [ ] 3. VPC network created
- [ ] 4. Subnet with secondary ranges
- [ ] 5. Firewall rules
- [ ] 6. GKE cluster overview
- [ ] 7. Nodes in terminal (kubectl get nodes)
- [ ] 8. Nodes in console
- [ ] 9. Cloud SQL instance
- [ ] 10. Cloud SQL databases
- [ ] 11. Cloud SQL private IP
- [ ] 12. Memorystore Redis instance
- [ ] 13. Redis connection details
- [ ] 14. Storage buckets
- [ ] 15. Pods running (kubectl get pods)
- [ ] 16. Service with external IP
- [ ] 17. Successful curl test
- [ ] 18. HPA configured
- [ ] 19. Pod auto-healing demo
- [ ] 20. Failed deployment (ImagePullBackOff)
- [ ] 21. Successful rollback
- [ ] 22. Cluster overview in console
- [ ] 23. Workloads view
- [ ] 24. Services view
- [ ] 25. Final infrastructure summary

---

## Skills Demonstrated

- Google Kubernetes Engine (GKE) cluster management
- Cloud SQL database deployment and configuration
- Memorystore Redis caching layer
- VPC networking with custom subnets and secondary IP ranges
- Firewall rule configuration for security
- Kubernetes deployments and services
- Load balancer configuration
- Horizontal Pod Autoscaling (HPA)
- Chaos engineering (pod deletion, rollback testing)
- Infrastructure as Code with gcloud CLI
- Site Reliability Engineering principles
- Zero-downtime deployments
- Cost analysis and optimization

---

**Deployment Time**: ~25-30 minutes  
**Skill Level**: Intermediate to Advanced  
**Certification Alignment**: Google Cloud Professional Cloud Architect
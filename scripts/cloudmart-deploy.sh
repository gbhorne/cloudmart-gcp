#!/bin/bash
# CloudMart E-commerce Platform Deployment Script
# Project: playground-s-11-60fe91d0

set -e

PROJECT_ID="playground-s-11-60fe91d0"
REGION="us-central1"

echo "========================================="
echo " CloudMart Platform Deployment"
echo "========================================="
echo ""

# Step 1: Configure project
echo "Step 1: Configuring project..."
gcloud config set project $PROJECT_ID
gcloud config set compute/region $REGION
gcloud config set compute/zone ${REGION}-a

# Step 2: Enable APIs
echo "Step 2: Enabling APIs..."
gcloud services enable \
    container.googleapis.com \
    sqladmin.googleapis.com \
    redis.googleapis.com \
    storage-api.googleapis.com \
    compute.googleapis.com \
    servicenetworking.googleapis.com \
    monitoring.googleapis.com \
    logging.googleapis.com

# Step 3: Create VPC
echo "Step 3: Creating VPC network..."
gcloud compute networks create cloudmart-vpc \
    --subnet-mode=custom \
    --bgp-routing-mode=regional

# Step 4: Create Subnet
echo "Step 4: Creating subnet..."
gcloud compute networks subnets create cloudmart-subnet \
    --network=cloudmart-vpc \
    --region=$REGION \
    --range=10.0.0.0/20 \
    --secondary-range=pods=10.4.0.0/14 \
    --secondary-range=services=10.0.16.0/20 \
    --enable-private-ip-google-access

# Step 5: Create firewall rules
echo "Step 5: Creating firewall rules..."
gcloud compute firewall-rules create cloudmart-allow-internal \
    --network=cloudmart-vpc \
    --allow=tcp,udp,icmp \
    --source-ranges=10.0.0.0/20,10.4.0.0/14,10.0.16.0/20

gcloud compute firewall-rules create cloudmart-allow-lb-health-checks \
    --network=cloudmart-vpc \
    --allow=tcp \
    --source-ranges=35.191.0.0/16,130.211.0.0/22 \
    --target-tags=gke-node

# Step 6: Create GKE cluster
echo "Step 6: Creating GKE cluster (this takes 8-10 minutes)..."
gcloud container clusters create cloudmart-cluster \
    --region=$REGION \
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

# Step 7: Configure kubectl
echo "Step 7: Configuring kubectl..."
gcloud container clusters get-credentials cloudmart-cluster --region=$REGION

# Step 8: Setup VPC peering for Cloud SQL
echo "Step 8: Setting up VPC peering..."
gcloud compute addresses create google-managed-services-cloudmart \
    --global \
    --purpose=VPC_PEERING \
    --prefix-length=16 \
    --network=cloudmart-vpc

gcloud services vpc-peerings connect \
    --service=servicenetworking.googleapis.com \
    --ranges=google-managed-services-cloudmart \
    --network=cloudmart-vpc

# Step 9: Create Cloud SQL
echo "Step 9: Creating Cloud SQL (this takes 10-12 minutes)..."
gcloud sql instances create cloudmart-db \
    --database-version=POSTGRES_15 \
    --tier=db-f1-micro \
    --region=$REGION \
    --network=projects/$PROJECT_ID/global/networks/cloudmart-vpc \
    --no-assign-ip \
    --root-password=CloudMart2024!

# Step 10: Create databases
echo "Step 10: Creating databases..."
gcloud sql databases create products --instance=cloudmart-db
gcloud sql databases create orders --instance=cloudmart-db
gcloud sql databases create users --instance=cloudmart-db

# Step 11: Create application user
echo "Step 11: Creating application user..."
gcloud sql users create cloudmart \
    --instance=cloudmart-db \
    --password=CloudMart2024AppUser!

# Step 12: Create Redis
echo "Step 12: Creating Memorystore Redis..."
gcloud redis instances create cloudmart-cache \
    --size=1 \
    --region=$REGION \
    --network=projects/$PROJECT_ID/global/networks/cloudmart-vpc \
    --redis-version=redis_7_0 \
    --tier=basic

# Step 13: Create storage buckets
echo "Step 13: Creating Cloud Storage buckets..."
gsutil mb -p $PROJECT_ID -c STANDARD -l $REGION gs://$PROJECT_ID-images/
gsutil mb -p $PROJECT_ID -c STANDARD -l $REGION gs://$PROJECT_ID-static/
gsutil mb -p $PROJECT_ID -c STANDARD -l $REGION gs://$PROJECT_ID-receipts/

# Step 14: Create namespace
echo "Step 14: Creating Kubernetes namespace..."
kubectl create namespace cloudmart

echo ""
echo "========================================="
echo " Deployment Complete!"
echo "========================================="
echo ""
echo "Connection Details:"
echo "  Cloud SQL IP: $(gcloud sql instances describe cloudmart-db --format='value(ipAddresses[0].ipAddress)')"
echo "  Redis Host: $(gcloud redis instances describe cloudmart-cache --region=$REGION --format='value(host)')"
echo "  Redis Port: $(gcloud redis instances describe cloudmart-cache --region=$REGION --format='value(port)')"
echo ""
echo "Next: Deploy your applications to the cloudmart namespace"

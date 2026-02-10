#!/bin/bash
# CloudMart Cleanup Script
# CAUTION: This will delete all CloudMart resources

PROJECT_ID="playground-s-11-60fe91d0"
REGION="us-central1"

echo "========================================="
echo " CloudMart Cleanup - WARNING"
echo "========================================="
echo ""
echo "This will DELETE all CloudMart resources:"
echo "  - GKE Cluster"
echo "  - Cloud SQL Instance"
echo "  - Memorystore Redis"
echo "  - Storage Buckets"
echo "  - VPC Network"
echo ""
read -p "Are you sure? (type 'yes' to confirm): " confirm

if [ "$confirm" != "yes" ]; then
    echo "Cleanup cancelled."
    exit 0
fi

echo ""
echo "Starting cleanup..."

# Delete Kubernetes resources
echo "Deleting Kubernetes resources..."
kubectl delete namespace cloudmart --ignore-not-found=true

# Delete Redis
echo "Deleting Memorystore Redis..."
gcloud redis instances delete cloudmart-cache --region=$REGION --quiet || true

# Delete Cloud SQL
echo "Deleting Cloud SQL..."
gcloud sql instances delete cloudmart-db --quiet || true

# Delete GKE Cluster
echo "Deleting GKE cluster (this takes 5-10 minutes)..."
gcloud container clusters delete cloudmart-cluster --region=$REGION --quiet || true

# Delete VPC Peering
echo "Deleting VPC peering..."
gcloud services vpc-peerings delete \
    --service=servicenetworking.googleapis.com \
    --network=cloudmart-vpc --quiet || true

# Delete IP range
echo "Deleting IP address range..."
gcloud compute addresses delete google-managed-services-cloudmart --global --quiet || true

# Delete Storage Buckets
echo "Deleting storage buckets..."
gsutil -m rm -r gs://$PROJECT_ID-images/ || true
gsutil -m rm -r gs://$PROJECT_ID-static/ || true
gsutil -m rm -r gs://$PROJECT_ID-receipts/ || true

# Delete Firewall Rules
echo "Deleting firewall rules..."
gcloud compute firewall-rules delete cloudmart-allow-internal --quiet || true
gcloud compute firewall-rules delete cloudmart-allow-lb-health-checks --quiet || true

# Delete Subnet
echo "Deleting subnet..."
gcloud compute networks subnets delete cloudmart-subnet --region=$REGION --quiet || true

# Delete VPC
echo "Deleting VPC..."
gcloud compute networks delete cloudmart-vpc --quiet || true

echo ""
echo "========================================="
echo " Cleanup Complete!"
echo "========================================="

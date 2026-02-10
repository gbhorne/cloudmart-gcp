# CloudMart E-commerce Platform on GCP
## Production-Grade Kubernetes Architecture with Chaos Engineering

[![GCP](https://img.shields.io/badge/Google%20Cloud-4285F4?style=for-the-badge&logo=google-cloud&logoColor=white)](https://cloud.google.com)
[![Kubernetes](https://img.shields.io/badge/Kubernetes-326CE5?style=for-the-badge&logo=kubernetes&logoColor=white)](https://kubernetes.io)
[![PostgreSQL](https://img.shields.io/badge/PostgreSQL-316192?style=for-the-badge&logo=postgresql&logoColor=white)](https://www.postgresql.org)

> **Project**: CloudMart - Modern e-commerce platform built on Google Cloud Platform with microservices architecture, demonstrating enterprise-grade cloud engineering and site reliability practices.

---

## Project Overview

CloudMart is a production-grade e-commerce platform deployed on Google Cloud Platform, showcasing:

- **Microservices Architecture** on Google Kubernetes Engine (GKE)
- **Multi-zone High Availability** across 3 availability zones
- **Managed Databases** with Cloud SQL PostgreSQL
- **Distributed Caching** with Memorystore Redis
- **Auto-scaling** with Horizontal Pod Autoscaler (HPA)
- **Chaos Engineering** validation with real failure scenarios
- **Zero-downtime Deployments** with rolling updates

---

## Architecture
```
┌─────────────────────────────────────────────────────┐
│              Load Balancer (35.184.40.233)          │
└──────────────────────┬──────────────────────────────┘
                       │
        ┌──────────────┴──────────────┐
        │   GKE Cluster (Regional)    │
        │   3 nodes (e2-medium)       │
        │   us-central1-a,b,c         │
        └──────────┬──────────────────┘
                   │
        ┌──────────┴──────────┐
        │   Kubernetes Pods   │
        │   Auto-scaling 2-5  │
        └──────────┬──────────┘
                   │
    ┌──────────────┼──────────────┐
    │              │              │
┌───▼────┐   ┌────▼────┐   ┌────▼─────┐
│Cloud SQL│   │Redis    │   │Storage   │
│10.177.0.3  │10.163.79│   │Buckets   │
│PostgreSQL│  │.243:6379│   │(Images)  │
└─────────┘   └─────────┘   └──────────┘
```

---

## Infrastructure Components

| Component | Configuration | Purpose |
|-----------|--------------|---------|
| **GKE Cluster** | 3 nodes, e2-medium, regional | Container orchestration |
| **Cloud SQL** | PostgreSQL 15, db-f1-micro | Relational database |
| **Memorystore** | Redis 7.0, 1GB, Basic tier | Session/cache storage |
| **Cloud Storage** | 3 buckets (images, static, receipts) | Object storage |
| **Load Balancer** | HTTP(S) Global LB | Traffic distribution |
| **VPC** | Custom network with secondary ranges | Network isolation |

---

## Quick Start

### Prerequisites

- Google Cloud Platform account
- gcloud CLI installed
- kubectl installed
- Project ID: `playground-s-11-60fe91d0`

### Deploy Infrastructure
```bash
# Clone repository
git clone https://github.com/yourusername/cloudmart-gcp.git
cd cloudmart-gcp

# Make deploy script executable
chmod +x cloudmart-deploy.sh

# Deploy (takes ~20 minutes)
./cloudmart-deploy.sh
```

### Verify Deployment
```bash
# Check GKE nodes
kubectl get nodes

# Check Cloud SQL
gcloud sql instances list

# Check Redis
gcloud redis instances list --region=us-central1

# Check buckets
gsutil ls
```

---

## Chaos Engineering Tests

### Test 1: Pod Auto-Healing

**Scenario**: Kill a pod and watch Kubernetes automatically recreate it
```bash
POD=$(kubectl get pods -n cloudmart -o jsonpath='{.items[0].metadata.name}')
kubectl delete pod $POD -n cloudmart
kubectl get pods -n cloudmart -w
```

**Expected Result**: 
- Pod terminates in <1 second
- New pod created automatically
- Recovery time: ~1 second
- Zero user impact

**Status**: PASSED

---

### Test 2: Bad Deployment Rollback

**Scenario**: Deploy broken image, verify zero downtime, rollback
```bash
# Deploy bad image
kubectl set image deployment/test-app nginx=nginx:broken -n cloudmart

# Watch failure
kubectl get pods -n cloudmart

# Rollback
kubectl rollout undo deployment/test-app -n cloudmart
```

**Expected Result**:
- Bad pods fail (ImagePullBackOff)
- Old pods continue serving traffic
- Rollback completes in <30 seconds
- Zero downtime

**Status**: PASSED

---

### Test 3: Horizontal Pod Autoscaling

**Scenario**: Configure HPA and verify scaling behavior
```bash
# Create HPA
kubectl autoscale deployment test-app --cpu-percent=50 --min=2 --max=5 -n cloudmart

# Check HPA
kubectl get hpa -n cloudmart
```

**Expected Result**:
- Min replicas: 2
- Max replicas: 5
- Scales based on CPU utilization

**Status**: CONFIGURED

---

## Cost Analysis

### Monthly Cost Breakdown

| Component | Monthly Cost |
|-----------|--------------|
| GKE (3 × e2-medium) | $73 |
| Cloud SQL (db-f1-micro) | $8 |
| Memorystore (1GB Redis) | $38 |
| Cloud Storage (100GB) | $2 |
| Load Balancer | $18 |
| Monitoring/Logging | $10 |
| **Total** | **~$149/month** |

### Cost Optimization Opportunities

- Use preemptible nodes: Save 60-80% on compute ($73 → $20)
- Committed use discounts: Save 25% with 1-year commitment
- Right-size database: Scale up only when needed
- **Optimized monthly cost**: ~$100-120/month

---

## Skills Demonstrated

### Cloud Architecture
- Multi-zone high availability design
- VPC networking and subnets
- Private IP addressing and VPC peering
- Firewall rules and security groups
- Load balancing and traffic management

### Kubernetes
- GKE cluster deployment and management
- Deployments and ReplicaSets
- Services (LoadBalancer, ClusterIP)
- Horizontal Pod Autoscaling (HPA)
- Zero-downtime rolling updates
- Rollback strategies

### Database Management
- Cloud SQL PostgreSQL configuration
- Private IP database access
- Database user management
- Multi-database architecture

### Caching & Performance
- Memorystore Redis setup
- Cache-aside pattern
- Session storage strategy

### Site Reliability Engineering
- Chaos engineering testing
- Auto-healing validation
- Failure scenario analysis
- Recovery time objectives (RTO)

### Infrastructure as Code
- gcloud CLI automation
- Bash scripting
- Deployment automation
- Idempotent infrastructure

---

## Architecture Trade-offs

### Why GKE vs App Engine?

| Decision Factor | GKE | App Engine |
|----------------|-----|------------|
| Container control | Full control | Limited |
| Microservices | Native K8s | Basic support |
| Scaling | Pod-level, fine-grained | Instance-level |
| Portability | High (multi-cloud) | GCP-only |
| Complexity | Higher | Lower |

**Decision**: GKE chosen for microservices architecture, fine-grained scaling, and multi-cloud portability.

---

### Why Cloud SQL vs Cloud Spanner?

| Decision Factor | Cloud SQL | Cloud Spanner |
|----------------|-----------|---------------|
| Scale | Regional, vertical | Global, horizontal |
| Cost | $8/month | $90+/month |
| Latency | <5ms regional | <10ms global |
| Use case | Regional apps | Global apps |

**Decision**: Cloud SQL chosen for regional deployment, cost constraints ($8 vs $90), and sufficient scale for MVP.

---

## Screenshots

See `screenshots/` folder for:
- GKE cluster overview
- Cloud SQL instance details
- Memorystore Redis configuration
- Pod auto-healing demonstration
- Rollback demonstration
- Monitoring dashboards

---

## CI/CD Pipeline (Future Enhancement)
```yaml
# Planned pipeline stages
1. Code commit → GitHub
2. Build containers → Cloud Build
3. Push images → Artifact Registry
4. Deploy to GKE → kubectl apply
5. Run smoke tests
6. Promote to production
```

---

## Security Considerations

- Private IP for databases (no public exposure)
- VPC network isolation
- Firewall rules (least privilege)
- Secret management via Kubernetes Secrets
- Workload Identity for GKE
- IAM restrictions (sandbox limitations)

---

## Cleanup

To delete all resources:
```bash
chmod +x cloudmart-cleanup.sh
./cloudmart-cleanup.sh
```

**Warning**: This will permanently delete all CloudMart infrastructure.

---

## Documentation

- [Architecture Deep Dive](docs/ARCHITECTURE.md)
- [Trade-off Analysis](docs/TRADEOFFS.md)
- [Cost Analysis](docs/COST-ANALYSIS.md)
- [Chaos Testing Guide](docs/CHAOS-TESTING.md)
- [Troubleshooting](docs/TROUBLESHOOTING.md)

---

## Success Criteria

| Criterion | Target | Achieved | Status |
|-----------|--------|----------|--------|
| **Infrastructure** | All components deployed | Yes | PASSED |
| **High Availability** | Multi-zone deployment | 3 zones | PASSED |
| **Auto-Scaling** | HPA configured | 2-5 replicas | PASSED |
| **Auto-Healing** | Pod recreation | <1s recovery | PASSED |
| **Zero Downtime** | Rolling updates | Validated | PASSED |
| **Cost** | <$200/month | $149/month | PASSED |

---

## Author

**Your Name**  
Cloud Solutions Architect

[![GitHub](https://img.shields.io/badge/GitHub-yourusername-181717?style=flat&logo=github)](https://github.com/yourusername)
[![LinkedIn](https://img.shields.io/badge/LinkedIn-Connect-0077B5?style=flat&logo=linkedin)](https://linkedin.com/in/yourusername)

---

## License

MIT License - See LICENSE file for details

---

## Acknowledgments

- Google Cloud Platform Documentation
- Kubernetes Best Practices
- Site Reliability Engineering (Google SRE Book)

---

**Built on Google Cloud Platform**

*Demonstrating production-grade cloud architecture and site reliability engineering*

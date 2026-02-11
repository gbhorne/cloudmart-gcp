\#  CloudMart Security Architecture



\## Overview



CloudMart is built using a private-by-default, defense-in-depth network architecture on Google Cloud Platform. The platform leverages VPC-native Google Kubernetes Engine (GKE), Private Service Access, regional high availability, and managed autoscaling to minimize attack surface while preserving global availability.



All infrastructure and data-layer traffic operates exclusively on private RFC1918 address space within controlled VPC CIDR ranges.



> All compute, pod, service, and managed database traffic operates entirely on private RFC1918 address space allocated from controlled VPC CIDR pools, with no direct public IP exposure at the node or data layer. External access is restricted to a managed Google load balancer, minimizing attack surface while preserving global availability.



---



\## Network Segmentation Model



CloudMart runs inside a custom VPC with explicitly defined IP allocation boundaries:



| Layer | CIDR Range | Purpose |

|--------|------------|----------|

| Nodes (Primary Subnet) | `10.0.0.0/20` | GKE worker infrastructure |

| Pods (Secondary Range) | `10.4.0.0/14` | Workload alias IP allocation |

| Services (Secondary Range) | `10.0.16.0/20` | ClusterIP internal services |

| Managed Services | Reserved `/16` range | Cloud SQL \& Redis via Private Service Access |



This segmentation enforces separation between:



\- Infrastructure  

\- Application workloads  

\- Service discovery  

\- Managed databases and caching  



Each layer operates within controlled, non-overlapping CIDR boundaries.



---



\## Private Compute Layer (GKE)



The CloudMart platform runs on a regional GKE cluster with:



\- Control plane replicated across multiple zones  

\- Worker nodes distributed across zones in `us-central1`  

\- No public IP addresses assigned to nodes  

\- VPC-native alias IP networking enabled  



\### Security Benefits



\- Nodes are not directly reachable from the internet  

\- No SSH exposure at the VM level  

\- East-west traffic remains internal  

\- Full VPC routing visibility and control  



All inbound traffic must traverse a managed Google load balancer.



---



\## VPC-Native (Alias IP) Networking



CloudMart uses VPC-native GKE with alias IPs, meaning:



\- Each Pod receives a unique IP address from the Pod CIDR range  

\- No overlay network or IP masquerading is used  

\- Pod-to-Pod communication occurs over native VPC routing  

\- Firewall policies and flow logs apply cleanly  



This provides:



\- Improved observability  

\- Simplified policy enforcement  

\- Clear traffic isolation  

\- Reduced internal network ambiguity  



---



\## Controlled Ingress Model



Public traffic enters the system through a single managed boundary:



```

Internet

  ↓

Google Global HTTP(S) Load Balancer

  ↓

Private GKE Node (10.0.0.0/20)

  ↓

Private Pod (10.4.0.0/14)

  ↓

Private Database / Cache

```



Security controls include:



\- Restricted health check IP ranges  

\- No direct NodePort exposure  

\- No broad inbound firewall rules  

\- No public database endpoints  



The attack surface is limited to the Google-managed load balancer.



---



\## Private Service Access (Cloud SQL \& Redis)



CloudMart deploys Cloud SQL (PostgreSQL) and Memorystore Redis using Private Service Access (VPC Peering).



Characteristics:



\- No public IP assigned to Cloud SQL  

\- No public IP assigned to Redis  

\- Managed services receive private IPs from a reserved peering range  

\- Traffic remains on Google’s private backbone  



Database traffic flow:



```

Pod (10.4.x.x)

  ↓

Private VPC Peering

  ↓

Cloud SQL Private IP (10.x.x.x)

```



\### Security Advantages



\- Eliminates public database exposure  

\- Reduces DDoS surface  

\- Prevents direct internet-based probing  

\- Enforces network-layer isolation  



Even if application credentials are compromised, the database remains unreachable from outside the VPC.



---



\## Firewall Controls



Two primary firewall policies are enforced:



\### Internal Communication Rule



Allows controlled east-west traffic only within defined CIDR ranges.



\### Load Balancer Health Check Rule



Allows ingress only from Google-managed health check IP ranges.



No broad internet ingress rules exist at the node layer.



---



\## Blast Radius Containment



Network segmentation significantly limits lateral movement:



\- Pods operate within a dedicated CIDR range  

\- Services use a separate service IP range  

\- Managed services reside in a peered private range  

\- Nodes are not internet-addressable  



If a workload is compromised:



\- It remains confined to its IP segment  

\- It cannot expose databases publicly  

\- It cannot bypass the load balancer  

\- It cannot reach external endpoints unless explicitly allowed  



This architecture reduces pivot opportunities and internal attack propagation.



---



\## Automated Security \& Resilience Controls



CloudMart leverages managed platform features to reinforce security posture:



\- Auto-repair replaces unhealthy nodes automatically  

\- Auto-upgrade applies security patches  

\- Horizontal Pod Autoscaling (HPA) adjusts to load without expanding public exposure  

\- Cluster Autoscaler adds nodes only when necessary  

\- Rolling deployments with rollback prevent bad releases from causing downtime  



Security posture improves continuously without manual intervention.



---



\## High Availability \& Failure Resilience



The regional GKE cluster provides:



\- Multi-zone node distribution  

\- Survives single-zone outages  

\- Automatic pod rescheduling  

\- No single point of compute failure  



Chaos testing confirms:



\- Pod deletion → auto-heal  

\- Traffic spike → HPA scales  

\- Node deletion → pods rescheduled  

\- Bad deployment → immediate rollback  

\- Zone failure → service continuity  



Availability is preserved without increasing exposure.



---



\## Security Design Principles Applied



CloudMart aligns with modern enterprise cloud security standards:



\- Private-by-default infrastructure  

\- Segmented IP allocation  

\- Managed ingress boundary  

\- No public database exposure  

\- Minimal attack surface  

\- Automated patching  

\- Defense-in-depth networking  



---



\## Security Summary



CloudMart is architected to:



\- Keep all compute and data-layer traffic private  

\- Restrict public access to a single managed entry point  

\- Enforce network segmentation across layers  

\- Limit blast radius during compromise  

\- Maintain availability during infrastructure failure  

\- Improve security posture automatically over time  



The result is a secure, private, autoscaling, and self-healing Kubernetes platform aligned with modern cloud-native security best practices.




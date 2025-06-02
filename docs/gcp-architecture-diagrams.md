# Google Cloud Landing Zone Architecture - Banking Group

*Version: 1.0*
*Date: May 21, 2025*

## Table of Contents

1. [Introduction](#1-introduction)
2. [Guiding Principles & Compliance](#2-guiding-principles--compliance)
3. [Google Cloud Organization and Resource Hierarchy](#3-google-cloud-organization-and-resource-hierarchy)
4. [Identity and Access Management (IAM)](#4-identity-and-access-management-iam)
5. [Networking and Connectivity](#5-networking-and-connectivity)
   - [5.1 Network Topology](#51-network-topology)
   - [5.2 IP Addressing & BGP](#52-ip-addressing--bgp)
   - [5.3 Internet Egress](#53-internet-egress)
   - [5.4 Access to Google APIs](#54-access-to-google-apis)
   - [5.5 Firewall Architecture](#55-firewall-architecture)
   - [5.6 DNS Architecture](#56-dns-architecture)
6. [Security and Compliance Controls](#6-security-and-compliance-controls)
7. [AI/ML & Data-Analytics Platform Architecture](#7-aiml--data-analytics-platform-architecture)
8. [Hybrid & Multi-Cloud Integration](#8-hybrid--multi-cloud-integration)
9. [Operations & Observability](#9-operations--observability)
10. [Infrastructure as Code (IaC) & Automation](#10-infrastructure-as-code-iac--automation)
11. [Terraform Strategy](#11-terraform-strategy)


---

## 1. Introduction

This document details the Google Cloud Landing Zone Architecture for the Banking Group, providing a secure, compliant, scalable, and automated foundation for AI/ML and data-analytics workloads within a hybrid cloud context.

The architecture implements a policy-driven approach using Infrastructure as Code (IaC) with Terraform to ensure repeatable and consistent deployments.

```mermaid
graph TD
    A[Banking Group<br>Google Cloud Landing Zone] --> B[Secure-by-Default]
    A --> C[Compliance Adherence]
    A --> D[Hybrid Connectivity]
    A --> E[Operational Excellence]
    A --> F[Automation]
    
    B --> B1[IAM Least Privilege]
    B --> B2[VPC Service Controls]
    B --> B3[Customer-Managed<br>Encryption Keys]
    
    C --> C1[SARB Compliance]
    C --> C2[POPIA Compliance]
    C --> C3[Global Banking<br>Security Standards]
    
    D --> D1[Resilient Connectivity<br>to On-Prem]
    D --> D2[Multi-Region Support]
    
    E --> E1[Centralized Logging]
    E --> E2[Monitoring]
    E --> E3[Policy Enforcement]
    
    F --> F1[Terraform IaC]
    F --> F2[Cloud Build CI/CD]

    classDef primary fill:#4285F4,stroke:#333,stroke-width:1px,color:white;
    classDef secondary fill:#34A853,stroke:#333,stroke-width:1px,color:white;
    class A primary;
    class B,C,D,E,F secondary;
```

---

## 2. Guiding Principles & Compliance

The architecture is founded on key principles and compliance requirements to ensure a secure and compliant cloud environment for banking operations.

```mermaid
graph TD
    A[Guiding Principles<br>& Compliance] --> B[Google Cloud<br>Architecture Framework]
    A --> C[Regulatory Compliance]
    A --> D[Security-by-Default]
    A --> E[Hybrid Integration]
    
    C --> C1[SARB]
    C --> C2[POPIA]
    C --> C3[Data Residency:<br>africa-south1]
    
    D --> D1[Least-privilege IAM]
    D --> D2[VPC Service Control<br>Perimeter]
    D --> D3[Customer-Managed<br>Encryption Keys]
    D --> D4[Security Command<br>Center]
    D --> D5[Strict Network<br>Firewall Policies]
    
    E --> E1[On-prem Active<br>Directory Integration]
    E --> E2[Internet Egress via<br>On-Premises]

    classDef primary fill:#4285F4,stroke:#333,stroke-width:1px,color:white;
    classDef secondary fill:#34A853,stroke:#333,stroke-width:1px,color:white;
    classDef tertiary fill:#FBBC05,stroke:#333,stroke-width:1px,color:black;
    class A primary;
    class B,C,D,E secondary;
    class C1,C2,C3,D1,D2,D3,D4,D5,E1,E2 tertiary;
```

---

## 3. Google Cloud Organization and Resource Hierarchy

The resource hierarchy provides structure for governance, cost management, and operational efficiency.

```mermaid
graph TD
    ORG[Organization: bank.example] --> FOLDER_SHARED[Folder: 00-Shared-Services]
    ORG --> FOLDER_PROD[Folder: 10-Prod-Environments]
    ORG --> FOLDER_NONPROD[Folder: 20-Non-Prod-Environments]
    ORG --> FOLDER_SANDBOX[Folder: 30-Sandbox-Environments]
    
    FOLDER_SHARED --> PRJ_TRANSIT[Project: Transit-Connectivity]
    FOLDER_SHARED --> PRJ_VPC_ZA[Project: Shared-VPC-Host-ZA]
    FOLDER_SHARED --> PRJ_VPC_LON[Project: Shared-VPC-Host-LON]
    FOLDER_SHARED --> PRJ_SEC[Project: Security-Tools]
    FOLDER_SHARED --> PRJ_LOG[Project: Logging]
    FOLDER_SHARED --> PRJ_MON[Project: Monitoring]
    
    FOLDER_PROD --> BU_RETAIL_PROD[Folder: bu-retail-prod]
    BU_RETAIL_PROD --> PROJ_RETAIL_PROD[Project: Workload-Retail-Prod]
    
    FOLDER_NONPROD --> BU_RETAIL_DEV[Folder: bu-retail-dev]
    BU_RETAIL_DEV --> PROJ_RETAIL_DEV[Project: Workload-Retail-Dev]
    
    FOLDER_NONPROD --> BU_RETAIL_UAT[Folder: bu-retail-uat]
    BU_RETAIL_UAT --> PROJ_RETAIL_UAT[Project: Workload-Retail-UAT]
    
    FOLDER_SANDBOX --> PROJ_SANDBOX[Project: Sandbox-Projects]
    
    classDef org fill:#4285F4,stroke:#333,stroke-width:1px,color:white;
    classDef folder fill:#34A853,stroke:#333,stroke-width:1px,color:white;
    classDef project fill:#FBBC05,stroke:#333,stroke-width:1px,color:black;
    class ORG org;
    class FOLDER_SHARED,FOLDER_PROD,FOLDER_NONPROD,FOLDER_SANDBOX,BU_RETAIL_PROD,BU_RETAIL_DEV,BU_RETAIL_UAT folder;
    class PRJ_TRANSIT,PRJ_VPC_ZA,PRJ_VPC_LON,PRJ_SEC,PRJ_LOG,PRJ_MON,PROJ_RETAIL_PROD,PROJ_RETAIL_DEV,PROJ_RETAIL_UAT,PROJ_SANDBOX project;
```

### Folder & Project Responsibilities

```mermaid
graph LR
    subgraph "Organization: bank.co.za"
        subgraph "Shared Services Folder"
            A1[Transit Project<br>NCC Hub, Cloud Routers]
            A2[Shared VPC ZA Project<br>Hosts africa-south1 VPC]
            A3[Shared VPC LON Project<br>Hosts europe-west2 VPC]
            A4[Security Project<br>SCC, Policy Controller]
            A5[Logging Project<br>Log Sinks, Pub/Sub]
            A6[Monitoring Project<br>Monitoring Resources]
        end
        
        subgraph "Environment Folders"
            B1[Production<br>Business-Critical Workloads]
            B2[Non-Production<br>Dev, Test, UAT]
            B3[Sandbox<br>Experimentation]
        end
    end
    
    classDef folder fill:#34A853,stroke:#333,stroke-width:1px,color:white;
    classDef project fill:#FBBC05,stroke:#333,stroke-width:1px,color:black;
    class A1,A2,A3,A4,A5,A6 project;
    class B1,B2,B3 folder;
```

---

## 4. Identity and Access Management (IAM)

IAM strategy secures cloud resources through proper identity federation, authentication, and authorization.

```mermaid
graph TD
    A[Identity & Access<br>Management] --> B[Identity Source]
    A --> C[Authentication]
    A --> D[Authorization]
    A --> E[Workload Identity<br>Federation]
    A --> F[VPC Service Controls<br>Access Boundary]
    
    B --> B1[On-prem<br>Active Directory]
    B --> B2[Cloud Identity]
    B --> B3[Google Cloud<br>Directory Sync]
    
    C --> C1[Azure AD]
    C --> C2[SAML 2.0/OIDC<br>Federation]
    C --> C3[MFA]
    
    D --> D1[Group-based<br>IAM Roles]
    D --> D2[IAM Conditions]
    D --> D3[Least Privilege<br>Principle]
    
    E --> E1[Non-human Access]
    E --> E2[CI/CD Pipelines]
    E --> E3[On-prem Services]
    
    F --> F1[Single Perimeter]
    F --> F2[Context-aware<br>Access Policies]

    classDef primary fill:#4285F4,stroke:#333,stroke-width:1px,color:white;
    classDef secondary fill:#34A853,stroke:#333,stroke-width:1px,color:white;
    classDef tertiary fill:#FBBC05,stroke:#333,stroke-width:1px,color:black;
    class A primary;
    class B,C,D,E,F secondary;
    class B1,B2,B3,C1,C2,C3,D1,D2,D3,E1,E2,E3,F1,F2 tertiary;
```

### Identity Flow Diagram

```mermaid
sequenceDiagram
    participant User
    participant OnPremAD as On-Prem Active Directory
    participant AzureAD as Azure AD
    participant GCDS as Google Cloud Directory Sync
    participant CloudIdentity as Cloud Identity
    participant GCP as Google Cloud Platform
    
    User->>OnPremAD: Authenticates with corporate credentials
    OnPremAD-->>GCDS: Syncs users and groups
    GCDS-->>CloudIdentity: Provisions users and groups
    User->>AzureAD: Federates for GCP access
    AzureAD->>CloudIdentity: SAML/OIDC authentication
    CloudIdentity->>GCP: Authorizes with IAM roles/groups
    GCP-->>User: Grants access to resources
```

---

## 5. Networking and Connectivity

### 5.1 Network Topology

The network architecture follows a hub-and-spoke model with Global Network Connectivity Center.

```mermaid
graph TD
    subgraph "Google Cloud"
        NCC[Network Connectivity<br>Center Hub]
        
        subgraph "Shared VPC - africa-south1"
            SVPC_ZA[Shared VPC Host<br>Project ZA]
            SVPC_ZA_SUBNET1[Subnet: Prod]
            SVPC_ZA_SUBNET2[Subnet: Non-Prod]
            
            SVPC_ZA --> SVPC_ZA_SUBNET1
            SVPC_ZA --> SVPC_ZA_SUBNET2
        end
        
        subgraph "Shared VPC - europe-west2"
            SVPC_LON[Shared VPC Host<br>Project LON]
            SVPC_LON_SUBNET1[Subnet: Prod]
            SVPC_LON_SUBNET2[Subnet: Non-Prod]
            
            SVPC_LON --> SVPC_LON_SUBNET1
            SVPC_LON --> SVPC_LON_SUBNET2
        end
        
        NCC --> SVPC_ZA
        NCC --> SVPC_LON
    end
    
    subgraph "On-Premises"
        ONPREM[On-Prem Data Center]
        ONPREM_ROUTER1[Router 1]
        ONPREM_ROUTER2[Router 2]
        
        ONPREM --> ONPREM_ROUTER1
        ONPREM --> ONPREM_ROUTER2
    end
    
    INTERCONNECT1[Dedicated<br>Interconnect 1]
    INTERCONNECT2[Dedicated<br>Interconnect 2]
    
    ONPREM_ROUTER1 <--> INTERCONNECT1
    ONPREM_ROUTER2 <--> INTERCONNECT2
    INTERCONNECT1 <--> NCC
    INTERCONNECT2 <--> NCC
    
    classDef gcp fill:#4285F4,stroke:#333,stroke-width:1px,color:white;
    classDef onprem fill:#EA4335,stroke:#333,stroke-width:1px,color:white;
    classDef interconnect fill:#FBBC05,stroke:#333,stroke-width:1px,color:black;
    classDef subnet fill:#34A853,stroke:#333,stroke-width:1px,color:white;
    
    class NCC,SVPC_ZA,SVPC_LON gcp;
    class ONPREM,ONPREM_ROUTER1,ONPREM_ROUTER2 onprem;
    class INTERCONNECT1,INTERCONNECT2 interconnect;
    class SVPC_ZA_SUBNET1,SVPC_ZA_SUBNET2,SVPC_LON_SUBNET1,SVPC_LON_SUBNET2 subnet;
```

### 5.2 IP Addressing & BGP

```mermaid
graph TD
    subgraph "IP Addressing & BGP"
        GCP_IP[GCP Address Range<br>10.245.0.0/17]
        ONPREM_IP[On-Prem Address Ranges<br>RFC1918]
        BGP[Cloud Router ASN<br>YOUR_PRIVATE_ASN]
        
        GCP_IP -- "Advertised to" --> ONPREM_IP
        ONPREM_IP -- "Advertised to" --> GCP_IP
        BGP -- "Enables exchange" --> GCP_IP
        BGP -- "Enables exchange" --> ONPREM_IP
    end
    
    classDef ip fill:#4285F4,stroke:#333,stroke-width:1px,color:white;
    classDef bgp fill:#34A853,stroke:#333,stroke-width:1px,color:white;
    
    class GCP_IP,ONPREM_IP ip;
    class BGP bgp;
```

### 5.3 Internet Egress

```mermaid
graph LR
    subgraph "Google Cloud"
        GCP_SVC[GCP Services]
        INTERCONNECT[Dedicated Interconnects]
    end
    
    subgraph "On-Premises"
        ONPREM_NETWORK[On-Prem Network]
        SECURITY_GATEWAY[Security Gateway<br>Firewalls & Proxies]
        INTERNET[Internet]
    end
    
    GCP_SVC --> INTERCONNECT
    INTERCONNECT --> ONPREM_NETWORK
    ONPREM_NETWORK --> SECURITY_GATEWAY
    SECURITY_GATEWAY --> INTERNET
    
    classDef gcp fill:#4285F4,stroke:#333,stroke-width:1px,color:white;
    classDef onprem fill:#EA4335,stroke:#333,stroke-width:1px,color:white;
    classDef internet fill:#34A853,stroke:#333,stroke-width:1px,color:white;
    
    class GCP_SVC,INTERCONNECT gcp;
    class ONPREM_NETWORK,SECURITY_GATEWAY onprem;
    class INTERNET internet;
```

### 5.4 Access to Google APIs

```mermaid
graph LR
    subgraph "Google Cloud VPC"
        VM[VM Instances<br>Private IP Only]
        SUBNET[Subnet with<br>Private Google Access]
    end
    
    RESTRICTED_API[restricted.googleapis.com]
    
    VM --> SUBNET
    SUBNET -- "Private access via" --> RESTRICTED_API
    
    classDef gcp fill:#4285F4,stroke:#333,stroke-width:1px,color:white;
    classDef api fill:#34A853,stroke:#333,stroke-width:1px,color:white;
    
    class VM,SUBNET gcp;
    class RESTRICTED_API api;
```

### 5.5 Firewall Architecture

```mermaid
graph TD
    subgraph "Hierarchical Firewall Policies"
        ORG_FIREWALL[Organization-level<br>Firewall Policies]
        FOLDER_FIREWALL[Folder-level<br>Firewall Policies]
    end
    
    subgraph "VPC Firewall Rules"
        VPC_FIREWALL[VPC Network<br>Firewall Rules]
        DEFAULT_DENY[Default Deny-All<br>Egress Rule]
        TAG_RULES[Tag-based<br>Allow Rules]
    end
    
    ORG_FIREWALL --> FOLDER_FIREWALL
    FOLDER_FIREWALL --> VPC_FIREWALL
    VPC_FIREWALL --> DEFAULT_DENY
    VPC_FIREWALL --> TAG_RULES
    
    classDef hierarchy fill:#4285F4,stroke:#333,stroke-width:1px,color:white;
    classDef vpc fill:#EA4335,stroke:#333,stroke-width:1px,color:white;
    
    class ORG_FIREWALL,FOLDER_FIREWALL hierarchy;
    class VPC_FIREWALL,DEFAULT_DENY,TAG_RULES vpc;
```

### 5.6 DNS Architecture

```mermaid
graph TD
    subgraph "On-Premises"
        ONPREM_BIND[On-Prem BIND<br>DNS Servers]
    end
    
    subgraph "Google Cloud"
        subgraph "Cloud DNS"
            PRIVATE_ZONES[Private DNS Zones<br>gcp.bank.example]
            PUBLIC_ZONES[Public DNS Zones<br>bank.example]
            INBOUND_POLICY[Inbound DNS<br>Server Policy]
            OUTBOUND_POLICY[Outbound DNS<br>Forwarding Zone]
        end
    end
    
    ONPREM_BIND -- "Conditional forwarding for<br>GCP zones" --> INBOUND_POLICY
    OUTBOUND_POLICY -- "Forwards on-prem<br>DNS queries" --> ONPREM_BIND
    
    classDef onprem fill:#EA4335,stroke:#333,stroke-width:1px,color:white;
    classDef clouddns fill:#4285F4,stroke:#333,stroke-width:1px,color:white;
    
    class ONPREM_BIND onprem;
    class PRIVATE_ZONES,PUBLIC_ZONES,INBOUND_POLICY,OUTBOUND_POLICY clouddns;
```

---

## 6. Security and Compliance Controls

A comprehensive set of security controls protect data and workloads in the cloud.

```mermaid
graph TD
    A[Security & Compliance<br>Controls] --> B[Data Residency<br>& Encryption]
    A --> C[Workload Isolation]
    A --> D[Monitoring &<br>Threat Detection]
    A --> E[Policy Enforcement]
    A --> F[Logging & SIEM<br>Integration]
    
    B --> B1[Primary: africa-south1]
    B --> B2[DR: europe-west2]
    B --> B3[CMEK with Cloud KMS]
    
    C --> C1[VPC Service Controls]
    C --> C2[Hierarchical Firewalls]
    
    D --> D1[Security Command<br>Center - Standard Tier]
    
    E --> E1[Policy Controller]
    E --> E2[Anthos Config<br>Management]
    
    F --> F1[Cloud Logging]
    F --> F2[Pub/Sub]
    F --> F3[Splunk (On-Prem)]

    classDef primary fill:#4285F4,stroke:#333,stroke-width:1px,color:white;
    classDef secondary fill:#34A853,stroke:#333,stroke-width:1px,color:white;
    classDef tertiary fill:#FBBC05,stroke:#333,stroke-width:1px,color:black;
    class A primary;
    class B,C,D,E,F secondary;
    class B1,B2,B3,C1,C2,D1,E1,E2,F1,F2,F3 tertiary;
```

### Security Architecture Diagram

```mermaid
graph TD
    subgraph "Google Cloud"
        subgraph "VPC Service Control Perimeter"
            GCS[Cloud Storage]
            BQ[BigQuery]
            AI[Vertex AI]
            SQL[Cloud SQL]
        end
        
        KMS[Cloud KMS<br>CMEK]
        SCC[Security Command<br>Center]
        LOGGING[Cloud Logging]
        PUBSUB[Pub/Sub]
        
        KMS --> GCS
        KMS --> BQ
        KMS --> AI
        KMS --> SQL
        
        GCS --> LOGGING
        BQ --> LOGGING
        AI --> LOGGING
        SQL --> LOGGING
        
        LOGGING --> PUBSUB
    end
    
    subgraph "On-Premises"
        SPLUNK[Splunk SIEM]
    end
    
    PUBSUB --> SPLUNK
    SCC -- "Monitors" --> GCS
    SCC -- "Monitors" --> BQ
    SCC -- "Monitors" --> AI
    SCC -- "Monitors" --> SQL
    
    classDef gcp fill:#4285F4,stroke:#333,stroke-width:1px,color:white;
    classDef security fill:#EA4335,stroke:#333,stroke-width:1px,color:white;
    classDef onprem fill:#34A853,stroke:#333,stroke-width:1px,color:white;
    
    class GCS,BQ,AI,SQL,LOGGING,PUBSUB gcp;
    class KMS,SCC security;
    class SPLUNK onprem;
```

---

## 7. AI/ML & Data-Analytics Platform Architecture

The landing zone supports advanced AI/ML and data analytics workloads.

```mermaid
graph LR
    subgraph "Data Sources"
        ONPREM_DATA[On-Prem<br>Data Sources]
        CLOUD_DATA[Cloud<br>Applications]
    end
    
    subgraph "Ingestion"
        PUBSUB[Pub/Sub]
    end
    
    subgraph "Processing"
        DATAFLOW[Dataflow]
    end
    
    subgraph "Storage"
        GCS[Cloud Storage<br>Data Lake]
    end
    
    subgraph "Analytics & ML"
        DATAPLEX[Dataplex]
        BQ[BigQuery]
        VERTEX[Vertex AI]
    end
    
    subgraph "Governance"
        CATALOG[Data Catalog]
        DLP[Cloud DLP]
    end
    
    ONPREM_DATA --> PUBSUB
    CLOUD_DATA --> PUBSUB
    PUBSUB --> DATAFLOW
    DATAFLOW --> GCS
    GCS --> DATAPLEX
    DATAPLEX --> BQ
    BQ --> VERTEX
    GCS --> CATALOG
    BQ --> CATALOG
    GCS <--> DLP
    BQ <--> DLP
    
    classDef source fill:#EA4335,stroke:#333,stroke-width:1px,color:white;
    classDef ingest fill:#4285F4,stroke:#333,stroke-width:1px,color:white;
    classDef process fill:#FBBC05,stroke:#333,stroke-width:1px,color:black;
    classDef storage fill:#34A853,stroke:#333,stroke-width:1px,color:white;
    classDef analytics fill:#4285F4,stroke:#333,stroke-width:1px,color:white;
    classDef governance fill:#EA4335,stroke:#333,stroke-width:1px,color:white;
    
    class ONPREM_DATA,CLOUD_DATA source;
    class PUBSUB ingest;
    class DATAFLOW process;
    class GCS storage;
    class DATAPLEX,BQ,VERTEX analytics;
    class CATALOG,DLP governance;
```

---

## 8. Hybrid & Multi-Cloud Integration

The architecture supports hybrid and multi-cloud scenarios for seamless workload and data management.

```mermaid
graph TD
    subgraph "Google Cloud"
        subgraph "Container Services"
            GKE[Google Kubernetes<br>Engine]
            ASM[Anthos Service Mesh]
        end
        
        subgraph "Data Services"
            BQ[BigQuery]
            PUBSUB[Pub/Sub]
            DMS[Database<br>Migration Service]
        end
        
        BQ_OMNI[BigQuery Omni]
    end
    
    subgraph "On-Premises"
        ANTHOS_ONPREM[GKE On-Prem]
        KAFKA[Kafka]
        ON_PREM_DB[On-Prem<br>Databases]
    end
    
    subgraph "Other Clouds"
        AWS_S3[AWS S3]
        AZURE_BLOB[Azure Blob<br>Storage]
    end
    
    GKE <--> ASM
    ANTHOS_ONPREM <--> ASM
    KAFKA <--> PUBSUB
    ON_PREM_DB <--> DMS
    DMS --> BQ
    AWS_S3 <--> BQ_OMNI
    AZURE_BLOB <--> BQ_OMNI
    BQ_OMNI --> BQ
    
    classDef gcp fill:#4285F4,stroke:#333,stroke-width:1px,color:white;
    classDef onprem fill:#EA4335,stroke:#333,stroke-width:1px,color:white;
    classDef aws fill:#FF9900,stroke:#333,stroke-width:1px,color:black;
    classDef azure fill:#0078D4,stroke:#333,stroke-width:1px,color:white;
    
    class GKE,ASM,BQ,PUBSUB,DMS,BQ_OMNI gcp;
    class ANTHOS_ONPREM,KAFKA,ON_PREM_DB onprem;
    class AWS_S3 aws;
    class AZURE_BLOB azure;
```

---

## 9. Operations & Observability

A comprehensive operations and observability stack ensures system health and performance.

```mermaid
graph TD
    subgraph "Google Cloud Observability"
        LOGGING[Cloud Logging]
        MONITORING[Cloud Monitoring]
        TRACE[Cloud Trace]
        PROFILER[Cloud Profiler]
        OTEL[OpenTelemetry<br>Collector]
    end
    
    subgraph "Alerting & Incident Management"
        PAGERDUTY[PagerDuty]
    end
    
    subgraph "External Systems"
        SPLUNK[Splunk SIEM]
    end
    
    subgraph "FinOps"
        BQ_BILLING[BigQuery<br>Billing Export]
        LOOKER[Looker Studio<br>Dashboards]
        RECOMMENDER[Recommender API]
    end
    
    LOGGING --> SPLUNK
    LOGGING --> MONITORING
    MONITORING --> PAGERDUTY
    TRACE --> MONITORING
    PROFILER --> MONITORING
    OTEL --> TRACE
    OTEL --> MONITORING
    BQ_BILLING --> LOOKER
    RECOMMENDER --> LOOKER
    
    classDef gcp fill:#4285F4,stroke:#333,stroke-width:1px,color:white;
    classDef external fill:#EA4335,stroke:#333,stroke-width:1px,color:white;
    classDef finops fill:#34A853,stroke:#333,stroke-width:1px,color:white;
    
    class LOGGING,MONITORING,TRACE,PROFILER,OTEL gcp;
    class PAGERDUTY,SPLUNK external;
    class BQ_BILLING,LOOKER,RECOMMENDER finops;
```

---

## 10. Infrastructure as Code (IaC) & Automation

Automation is a cornerstone of this architecture, with Terraform as the primary IaC tool.

```mermaid
graph TD
    subgraph "Infrastructure as Code"
        TERRAFORM[Terraform]
        MODULES[Terraform Module<br>Catalogue]
    end
    
    subgraph "CI/CD"
        CLOUDBUILD[Cloud Build]
        TRIGGERS[Build Triggers]
    end
    
    subgraph "Policy as Code"
        POLICY_CONTROLLER[Policy Controller]
        OPA[Open Policy Agent]
    end
    
    subgraph "Image Management"
        PACKER[Packer]
        OS_CONFIG[OS Config]
        VM_MANAGER[VM Manager]
    end
    
    TERRAFORM --> MODULES
    TERRAFORM --> CLOUDBUILD
    TRIGGERS --> CLOUDBUILD
    CLOUDBUILD --> OPA
    OPA --> POLICY_CONTROLLER
    PACKER --> OS_CONFIG
    OS_CONFIG --> VM_MANAGER
    
    classDef terraform fill:#4285F4,stroke:#333,stroke-width:1px,color:white;
    classDef cicd fill:#EA4335,stroke:#333,stroke-width:1px,color:white;
    classDef policy fill:#34A853,stroke:#333,stroke-width:1px,color:white;
    classDef image fill:#FBBC05,stroke:#333,stroke-width:1px,color:black;
    
    class TERRAFORM,MODULES terraform;
    class CLOUDBUILD,TRIGGERS cicd;
    class POLICY_CONTROLLER,OPA policy;
    class PACKER,OS_CONFIG,VM_MANAGER image;
```

### CI/CD Pipeline Flow

```mermaid
sequenceDiagram
    participant Dev as Developer
    participant Repo as Source Repository
    participant CB as Cloud Build
    participant OPA as Open Policy Agent
    participant TF as Terraform
    participant GCP as Google Cloud Resources
    
    Dev->>Repo: Push code changes
    Repo->>CB: Trigger build pipeline
    CB->>OPA: Validate policies
    alt Policy check fails
        OPA->>CB: Fail build
        CB->>Dev: Report violations
    else Policy check passes
        OPA->>CB: Pass validation
        CB->>TF: Run terraform plan
        TF->>CB: Return plan results
        CB->>Dev: Request approval (for prod)
        Dev->>CB: Approve changes
        CB->>TF: Run terraform apply
        TF->>GCP: Create/update resources
        GCP->>CB: Return status
        CB->>Dev: Report success
    end
```

---

## 11. Terraform Strategy

The effective use of Terraform is critical for successfully implementing and maintaining the landing zone.

```mermaid
graph TD
    A[Terraform Strategy] --> B[Modular Design]
    A --> C[Google-Provided<br>Modules]
    A --> D[State Management]
    A --> E[CI/CD Integration]
    A --> F[Secrets Management]
    
    B --> B1[Terraform Module<br>Catalogue]
    B --> B2[Reusable Components]
    
    C --> C1[Official Google<br>Terraform Modules]
    C --> C2[Custom Extensions]
    
    D --> D1[GCS Backend]
    D --> D2[State Versioning]
    D --> D3[State Locking]
    
    E --> E1[Cloud Build<br>Pipelines]
    E --> E2[Workspace<br>Management]
    E --> E3[Approval Gates]
    
    F --> F1[Secret Manager]
    F --> F2[Service Account<br>Access Control]
    
    classDef primary fill:#4285F4,stroke:#333,stroke-width:1px,color:white;
    classDef secondary fill:#34A853,stroke:#333,stroke-width:1px,color:white;
    classDef tertiary fill:#FBBC05,stroke:#333,stroke-width:1px,color:black;
    class A primary;
    class B,C,D,E,F secondary;
    class B1,B2,C1,C2,D1,D2,D3,E1,E2,E3,F1,F2 tertiary;
```

### Terraform Module Structure

```mermaid
graph TD
    subgraph "Terraform Module Catalogue"
        ORG_MODULE[Organization<br>Module]
        FOLDER_MODULE[Folder<br>Module]
        PROJECT_MODULE[Project Factory<br>Module]
        IAM_MODULE[IAM<br>Module]
        
        NETWORK_MODULE[Network<br>Module]
        VPC_SC_MODULE[VPC Service Controls<br>Module]
        GKE_MODULE[GKE<br>Module]
        KMS_MODULE[KMS<br>Module]
        
        LOGGING_MODULE[Logging & Monitoring<br>Module]
        DATAPROC_MODULE[Dataproc<br>Module]
        BQ_MODULE[BigQuery<br>Module]
        VERTEX_MODULE[Vertex AI<br>Module]
    end
    
    subgraph "Environment Configurations"
        PROD_CONFIG[Production<br>Configuration]
        NONPROD_CONFIG[Non-Production<br>Configuration]
    end
    
    PROD_CONFIG --> ORG_MODULE
    PROD_CONFIG --> FOLDER_MODULE
    PROD_CONFIG --> PROJECT_MODULE
    PROD_CONFIG --> IAM_MODULE
    PROD_CONFIG --> NETWORK_MODULE
    PROD_CONFIG --> VPC_SC_MODULE
    PROD_CONFIG --> GKE_MODULE
    PROD_CONFIG --> KMS_MODULE
    PROD_CONFIG --> LOGGING_MODULE
    PROD_CONFIG --> DATAPROC_MODULE
    PROD_CONFIG --> BQ_MODULE
    PROD_CONFIG --> VERTEX_MODULE
    
    NONPROD_CONFIG --> ORG_MODULE
    NONPROD_CONFIG --> FOLDER_MODULE
    NONPROD_CONFIG --> PROJECT_MODULE
    NONPROD_CONFIG --> IAM_MODULE
    NONPROD_CONFIG --> NETWORK_MODULE
    NONPROD_CONFIG --> VPC_SC_MODULE
    NONPROD_CONFIG --> GKE_MODULE
    NONPROD_CONFIG --> KMS_MODULE
    NONPROD_CONFIG --> LOGGING_MODULE
    NONPROD_CONFIG --> DATAPROC_MODULE
    NONPROD_CONFIG --> BQ_MODULE
    NONPROD_CONFIG --> VERTEX_MODULE
    
    classDef module fill:#4285F4,stroke:#333,stroke-width:1px,color:white;
    classDef config fill:#34A853,stroke:#333,stroke-width:1px,color:white;
    
    class ORG_MODULE,FOLDER_MODULE,PROJECT_MODULE,IAM_MODULE,NETWORK_MODULE,VPC_SC_MODULE,GKE_MODULE,KMS_MODULE,LOGGING_MODULE,DATAPROC_MODULE,BQ_MODULE,VERTEX_MODULE module;
    class PROD_CONFIG,NONPROD_CONFIG config;
```

## 12. End-to-End Architecture Overview

This comprehensive diagram brings together the key components of the Google Cloud Landing Zone architecture for the banking group.

```mermaid
graph TD
    subgraph "On-Premises"
        AD[Active Directory]
        AZURE_AD[Azure AD]
        SPLUNK[Splunk SIEM]
        ONPREM_DC[On-Prem Data Center]
        SECURITY_GW[Security Gateways]
    end
    
    subgraph "Google Cloud Organization"
        subgraph "Shared Services"
            NCC[Network Connectivity<br>Center Hub]
            SHARED_VPC_ZA[Shared VPC<br>africa-south1]
            SHARED_VPC_LON[Shared VPC<br>europe-west2]
            CLOUD_DNS[Cloud DNS]
            SCC[Security Command<br>Center]
            KMS[Cloud KMS]
            POLICY_CTRL[Policy Controller]
        end
        
        subgraph "Production Environment"
            PROD_PROJECTS[Production<br>Projects]
        end
        
        subgraph "Non-Production Environment"
            NONPROD_PROJECTS[Non-Production<br>Projects]
        end
        
        subgraph "Data & AI Platform"
            GCS[Cloud Storage]
            PUBSUB[Pub/Sub]
            DATAFLOW[Dataflow]
            BQ[BigQuery]
            VERTEX[Vertex AI]
            DATAPLEX[Dataplex]
        end
        
        subgraph "Operations"
            LOGGING[Cloud Logging]
            MONITORING[Cloud Monitoring]
            TRACE[Cloud Trace]
            BILLING[Billing Export<br>to BigQuery]
        end
    end
    
    subgraph "Developer Tools"
        TERRAFORM[Terraform]
        CLOUDBUILD[Cloud Build]
    end
    
    %% Identity & Access
    AD -- "Directory Sync" --> CLOUD_IDENTITY[Cloud Identity]
    AZURE_AD -- "Federation" --> CLOUD_IDENTITY
    CLOUD_IDENTITY -- "IAM" --> SHARED_VPC_ZA
    CLOUD_IDENTITY -- "IAM" --> SHARED_VPC_LON
    CLOUD_IDENTITY -- "IAM" --> PROD_PROJECTS
    CLOUD_IDENTITY -- "IAM" --> NONPROD_PROJECTS
    
    %% Networking
    ONPREM_DC -- "Dedicated<br>Interconnects" --> NCC
    NCC -- "Spoke" --> SHARED_VPC_ZA
    NCC -- "Spoke" --> SHARED_VPC_LON
    SHARED_VPC_ZA -- "Hosts" --> PROD_PROJECTS
    SHARED_VPC_ZA -- "Hosts" --> NONPROD_PROJECTS
    SHARED_VPC_LON -- "DR" --> PROD_PROJECTS
    CLOUD_DNS -- "Private Zones" --> SHARED_VPC_ZA
    CLOUD_DNS -- "Private Zones" --> SHARED_VPC_LON
    
    %% Internet Egress
    SHARED_VPC_ZA -- "Internet Traffic" --> ONPREM_DC
    ONPREM_DC -- "Egress" --> SECURITY_GW
    
    %% Security
    SCC -- "Monitors" --> SHARED_VPC_ZA
    SCC -- "Monitors" --> SHARED_VPC_LON
    SCC -- "Monitors" --> PROD_PROJECTS
    SCC -- "Monitors" --> NONPROD_PROJECTS
    SCC -- "Monitors" --> GCS
    SCC -- "Monitors" --> BQ
    KMS -- "CMEK" --> GCS
    KMS -- "CMEK" --> BQ
    KMS -- "CMEK" --> VERTEX
    POLICY_CTRL -- "Enforces" --> PROD_PROJECTS
    POLICY_CTRL -- "Enforces" --> NONPROD_PROJECTS
    
    %% Data Flow
    PROD_PROJECTS -- "Data" --> GCS
    PROD_PROJECTS -- "Events" --> PUBSUB
    PUBSUB -- "Streams" --> DATAFLOW
    DATAFLOW -- "Processes" --> GCS
    GCS -- "Analytics" --> BQ
    BQ -- "ML" --> VERTEX
    DATAPLEX -- "Governs" --> GCS
    DATAPLEX -- "Governs" --> BQ
    
    %% Operations
    PROD_PROJECTS -- "Logs" --> LOGGING
    NONPROD_PROJECTS -- "Logs" --> LOGGING
    GCS -- "Logs" --> LOGGING
    BQ -- "Logs" --> LOGGING
    VERTEX -- "Logs" --> LOGGING
    LOGGING -- "Export" --> SPLUNK
    PROD_PROJECTS -- "Metrics" --> MONITORING
    NONPROD_PROJECTS -- "Metrics" --> MONITORING
    BILLING -- "Cost Data" --> BQ
    
    %% IaC
    TERRAFORM -- "Deploys" --> PROD_PROJECTS
    TERRAFORM -- "Deploys" --> NONPROD_PROJECTS
    TERRAFORM -- "Deploys" --> SHARED_VPC_ZA
    TERRAFORM -- "Deploys" --> SHARED_VPC_LON
    TERRAFORM -- "Deploys" --> NCC
    CLOUDBUILD -- "Runs" --> TERRAFORM
    
    classDef onprem fill:#EA4335,stroke:#333,stroke-width:1px,color:white;
    classDef shared fill:#4285F4,stroke:#333,stroke-width:1px,color:white;
    classDef env fill:#34A853,stroke:#333,stroke-width:1px,color:white;
    classDef data fill:#FBBC05,stroke:#333,stroke-width:1px,color:black;
    classDef ops fill:#4285F4,stroke:#333,stroke-width:1px,color:white;
    classDef dev fill:#34A853,stroke:#333,stroke-width:1px,color:white;
    classDef identity fill:#673AB7,stroke:#333,stroke-width:1px,color:white;
    
    class AD,AZURE_AD,SPLUNK,ONPREM_DC,SECURITY_GW onprem;
    class NCC,SHARED_VPC_ZA,SHARED_VPC_LON,CLOUD_DNS,SCC,KMS,POLICY_CTRL shared;
    class PROD_PROJECTS,NONPROD_PROJECTS env;
    class GCS,PUBSUB,DATAFLOW,BQ,VERTEX,DATAPLEX data;
    class LOGGING,MONITORING,TRACE,BILLING ops;
    class TERRAFORM,CLOUDBUILD dev;
    class CLOUD_IDENTITY identity;
```

## 13. Conclusion

This comprehensive architecture document with integrated Mermaid diagrams provides a clear visualization of the Google Cloud Landing Zone for the Banking Group. The architecture establishes a secure, compliant, scalable, and automated foundation that supports AI/ML and data-analytics workloads within a hybrid cloud context.

Key architectural components are visualized to ensure all stakeholders understand:
- The resource hierarchy organization
- Identity and access management flows
- Network topology and connectivity
- Security and compliance controls
- Data and AI platform architecture
- Hybrid and multi-cloud integration approaches
- Operations and observability setup
- Infrastructure as Code and automation pipelines

By leveraging Terraform as the primary IaC tool, with a modular approach and integration with CI/CD pipelines, the bank can ensure consistent, reliable, and auditable infrastructure deployments that meet regulatory requirements while enabling innovation and business agility.

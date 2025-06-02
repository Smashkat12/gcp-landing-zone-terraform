# Google Cloud Landing Zone Architecture - Banking Group
*Prepared by: Cloud Architecture Team*  
*Date: May 21, 2025*

---

## 1. Executive Summary
This document details a **comprehensive, enterprise-scale Google Cloud Landing Zone** for a South African banking group. The architecture is designed to establish a secure, compliant, scalable, and automated foundation that supports AI/ML and data-analytics workloads within a hybrid cloud context, ensuring seamless integration with on-premises systems and adherence to stringent regulatory standards (SARB, POPIA).

Key features:
* **Secure-by-default approach** leveraging least-privilege IAM, VPC Service Controls, CMEK via Cloud KMS, and Security Command Center Standard Tier.
* **Well-defined resource hierarchy** with folders and projects organized by environment and function.
* **Hub-and-spoke network architecture** with dedicated interconnects from Johannesburg and resilient connectivity to on-premises infrastructure.
* **Policy-driven governance** with Terraform IaC and Cloud Build CI/CD pipelines.
* **Comprehensive AI/ML platform** using BigQuery, Vertex AI, and Dataplex.
* **Centralized operations** with Cloud Monitoring, Cloud Logging, and Splunk SIEM integration.

---

## 2. Guiding Principles & Compliance

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

* **Google Cloud Architecture Framework**: Aligned with Google's best practices for designing and operating cloud workloads.
* **Regulatory Compliance**: Designed to meet South African Reserve Bank (SARB) and Protection of Personal Information Act (POPIA) requirements, with `africa-south1` as the primary region for data residency.
* **Security-by-Default**: Implementing comprehensive security controls from the ground up including least-privilege IAM, VPC Service Controls, CMEK via Cloud KMS, and strict network policies.
* **Hybrid Integration**: Seamless integration with on-prem Active Directory and routing of internet egress via on-premises infrastructure.

---

## 3. Organization & Resource Hierarchy

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

The resource hierarchy provides structure for governance, cost management, and operational efficiency:

* **Organization**: `bank.example` (Top-level node)
* **Folders**: Provide isolation and policy inheritance
  * **Shared Services Folder**: Hosts centralized network, security, logging, and monitoring projects
  * **Production Environments Folder**: Contains all production workloads by business unit
  * **Non-Production Environments Folder**: Houses development, testing, and UAT environments
  * **Sandbox Environments Folder**: Provides isolated environments for experimentation
* **Projects**: Fundamental unit for resource deployment, billing, and IAM
  * Each project isolates resources for a specific application, environment, or service

---

## 4. Identity & Access Management

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

* **Identity Source**: On-prem Active Directory remains authoritative. Cloud Identity and Google Cloud Directory Sync (GCDS) are used for identity synchronization.
* **Authentication**: SAML 2.0 / OIDC federation with Azure AD for Multi-Factor Authentication (MFA) and conditional access.
* **Authorization**: Least-privilege principle enforced via group-based IAM roles and IAM conditions.
* **Workload Identity Federation**: Used for non-human access (CI/CD pipelines, on-prem services) to avoid service account keys.
* **Access Boundary**: A single VPC Service Controls perimeter protects critical Google Cloud services with context-aware access policies.
* **Managed Microsoft AD**: Optional deployment for AD-dependent workloads.

---

## 5. Networking & Connectivity

### 5.1 Network Topology

```mermaid
flowchart TD
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

* **Hub-and-Spoke Model**: Uses a Global Network Connectivity Center (NCC) Hub.
* **On-Prem Connectivity**: Dual 10Gbps Dedicated Interconnects from Johannesburg co-location, connecting as VLAN attachments to the NCC Hub.
* **GCP VPC Spokes**: Regional Shared VPCs in `africa-south1` (Primary) and `europe-west2` (DR) attached as spokes to the Global NCC Hub.
* **IP Addressing**: GCP Address Range: `10.245.0.0/17` (advertised to on-prem) with Standard RFC1918 ranges from on-prem.
* **Internet Egress**: All internet-bound traffic from GCP services is routed via the Interconnects to the on-premises network.
* **Private Google Access**: Configured for subnets using `restricted.googleapis.com`.
* **Firewall Architecture**: Hierarchical Firewall Policies applied at Organization/Folder levels with default deny-all egress from VPCs.

### 5.2 DNS Architecture

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

* **Split-Horizon DNS**: Different DNS views for internal and external resolution.
* **GCP Private Zones**: Cloud DNS private zones (e.g., `gcp.bank.example`) associated with regional Shared VPCs.
* **On-Prem to GCP Resolution**: On-prem BIND servers use conditional forwarding via Cloud DNS inbound server policies.
* **GCP to On-Prem Resolution**: Cloud DNS outbound server policies/forwarding zones point to on-prem BIND servers.
* **Public DNS**: Managed via Cloud DNS public zones (e.g., for `bank.example`).

---

## 6. Security & Compliance Controls

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

* **Data Residency**: Primary region is `africa-south1` (Johannesburg), DR region is `europe-west2` (London).
* **Encryption**: Default Customer-Managed Encryption Keys (CMEK) with Cloud KMS for critical services.
* **Workload Isolation**: A single comprehensive VPC Service Controls perimeter protects critical services, with hierarchical firewalls enforcing network segmentation.
* **Monitoring & Threat Detection**: Security Command Center (SCC) Standard Tier provides centralized visibility into security posture.
* **Policy Enforcement**: Policy Controller (Anthos Config Management) enables policy-as-code.
* **Logging & SIEM Integration**: Cloud Logging exports all critical audit, platform, and application logs via Pub/Sub to on-prem Splunk.

---

## 7. AI/ML & Data-Analytics Platform

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

* **Data Lifecycle Overview**:
  * **Ingestion**: Pub/Sub for real-time event streaming, potentially integrating with on-prem Kafka.
  * **Processing**: Dataflow for scalable batch and stream data processing.
  * **Storage**: Google Cloud Storage (GCS) for raw data, staging, and processed data (data lake).
  * **Lakehouse & Warehousing**: Dataplex for managing and governing data across GCS and BigQuery. BigQuery as the serverless data warehouse for analytics and ML.
  * **AI/ML Compute**: Vertex AI for custom model training, serving, and pre-built ML APIs.
  * **Governance**: Data Catalog for metadata management and discovery, Cloud Data Loss Prevention (DLP) for protecting sensitive data.

* **Security Integration**:
  * All AI/ML services operate within the established VPC Service Control perimeter.
  * CMEK encryption is used for data stored in GCS, BigQuery, and Vertex AI managed datasets.

---

## 8. Hybrid & Multi-Cloud Integration

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

* **Anthos**: Strategic platform for hybrid container workloads and service management.
  * **GKE on-prem**: Extends Google Kubernetes Engine to on-premises environments.
  * **Anthos Service Mesh**: Provides uniform observability, security, and control for microservices.
* **Database Migration Service (DMS)**: Facilitates migration of on-premises databases to Google Cloud.
* **BigQuery Omni**: Allows querying data residing in other clouds without moving the data.
* **Pub/Sub**: Acts as a global, scalable messaging service capable of bridging to on-prem systems like Kafka.

---

## 9. Operations & Observability

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

* **Core Tooling**:
  * **Cloud Logging**: Centralized log collection and analysis.
  * **Cloud Monitoring**: Metrics collection, dashboards, and alerting for GCP resources and applications.
* **Alerting**: PagerDuty integration for notifying on-call teams of critical issues.
* **Application Performance Management (APM)**:
  * **Cloud Trace**: Distributed tracing for understanding request latency.
  * **Cloud Profiler**: Continuous CPU and heap profiling to identify performance bottlenecks.
  * **OpenTelemetry Collector**: For collecting traces and metrics using open standards.
* **Log Management**: All critical logs exported to on-prem Splunk for long-term storage and analysis.
* **FinOps**:
  * **BigQuery Billing Export**: Granular billing data exported to BigQuery for analysis.
  * **Looker Studio Dashboards**: Visualization of cost data.
  * **Recommender API**: Provides cost optimization recommendations.

---

## 10. Infrastructure as Code & Automation

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

* **IaC Core**: Terraform as the primary tool for defining and provisioning all Google Cloud infrastructure.
* **CI/CD**: Cloud Build for continuous integration and continuous delivery pipelines.
* **Policy as Code**: Policy Controller defines and enforces organizational policies on GCP resources and Kubernetes clusters.
* **Golden Images & Patching**:
  * **Packer**: For creating hardened, standardized VM images.
  * **OS Config**: For managing OS configurations and patch deployment.
  * **VM Manager**: Suite of tools for managing OS environments on Compute Engine.

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

* **Modular Design**: A Terraform Module Catalogue will be developed, containing reusable modules for common infrastructure patterns.
* **Google-Provided Modules**: Where appropriate, Google's official Terraform modules will be utilized and potentially extended.
* **State Management**: Terraform state will be stored securely in Google Cloud Storage buckets with versioning and object locking.
* **CI/CD Integration**: Cloud Build pipelines will automate terraform plan and apply stages with workspaces for different environments.
* **Secrets Management**: Sensitive data will be managed using Google Cloud Secret Manager.

---

## 12. Implementation Roadmap

```mermaid
gantt
    title Implementation Roadmap
    dateFormat  YYYY-MM-DD
    section Foundations
    Organization & Resource Hierarchy    :a1, 2025-06-01, 14d
    IAM & Identity Federation           :a2, after a1, 21d
    Shared VPC & Networking             :a3, after a2, 28d
    
    section Security
    VPC Service Controls                :b1, after a3, 14d
    CMEK Implementation                 :b2, after b1, 14d
    Security Command Center             :b3, after b2, 7d
    
    section Platform
    Logging & Monitoring                :c1, after a3, 21d
    AI/ML & Data Platform               :c2, after b3, 28d
    Hybrid Integration                  :c3, after c2, 21d
    
    section Operations
    FinOps Implementation               :d1, after c1, 14d
    Application Migration               :d2, after c3, 28d
    Production Go-Live                  :milestone, after d2, 0d
```

The implementation of the Google Cloud Landing Zone will follow a phased approach:

| Phase | Timeline | Key Activities |
|-------|----------|----------------|
| 1. Foundations | Months 1-2 | - Organization setup<br>- Folder/project structure<br>- IAM federation<br>- Shared VPC deployment<br>- Interconnect provisioning |
| 2. Security | Month 3 | - VPC Service Controls<br>- CMEK implementation<br>- Security monitoring<br>- Logging exports |
| 3. Platform | Months 4-5 | - Monitoring & observability<br>- AI/ML platform setup<br>- Hybrid connectivity<br>- Policy enforcement |
| 4. Operations | Months 6-7 | - FinOps dashboards<br>- Application migration<br>- Production readiness<br>- Knowledge transfer |

---

## 13. End-to-End Architecture Overview

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

This comprehensive diagram brings together the key components of the Google Cloud Landing Zone architecture for the banking group, illustrating how all the components interact within a secure, compliant, and well-governed environment.

---

## 14. Key Design Decisions Summary

| Area | Decision | Rationale |
|------|----------|-----------|
| **Data Residency** | Primary: `africa-south1`<br>DR: `europe-west2` | Aligns with SARB & POPIA requirements while providing robust disaster recovery capabilities |
| **IAM Strategy** | On-prem AD + Cloud Identity federation via GCDS | Maintains existing identity source while leveraging cloud-native controls |
| **Network Design** | Hub-and-spoke with NCC and Shared VPCs | Centralized network control while allowing service project flexibility |
| **Internet Egress** | Via on-premises security controls | Leverages existing security investments and maintains uniform policy enforcement |
| **Security** | VPC-SC + CMEK + SCC Standard Tier | Defense-in-depth approach with multiple security layers |
| **AI/ML Platform** | Vertex AI + BigQuery + Dataplex | Comprehensive, managed platform with strong data governance capabilities |
| **Hybrid Strategy** | Anthos + Dedicated Interconnect | Consistent container platform across environments with high-bandwidth connectivity |
| **Operations** | Cloud Logging/Monitoring + Splunk integration | Combines cloud-native observability with enterprise SIEM integration |
| **Automation** | Terraform + Cloud Build + Policy Controller | Infrastructure as code with built-in policy guardrails and CI/CD integration |

---

## 15. Conclusion

This Google Cloud Landing Zone architecture provides a robust, secure, and scalable foundation for the banking group's cloud journey. By leveraging a well-defined resource hierarchy, centralized IAM, a resilient hybrid network, comprehensive security controls, and extensive automation through Terraform and Cloud Build, the bank can confidently deploy AI/ML and data analytics workloads while adhering to strict compliance and security mandates.

The emphasis on modularity, policy-as-code, and a strong FinOps practice will ensure the landing zone remains adaptable, governable, and cost-effective as the bank's cloud adoption matures. The architecture follows Google Cloud best practices and industry standards, providing a future-proof foundation that can evolve with the organization's needs.

---

## Appendices

### Appendix A: Terraform Module Catalogue

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

### Appendix B: Regulatory Control Mapping

| Regulatory Requirement | GCP Control Implementation |
|------------------------|----------------------------|
| **POPIA Section 19 - Security Safeguards** | - VPC Service Controls<br>- CMEK via Cloud KMS<br>- IAM & Organization Policies<br>- Cloud Audit Logs |
| **POPIA Section 20 - Information Processing** | - Data Loss Prevention (DLP)<br>- Dataplex Governance<br>- Data Catalog Tags |
| **POPIA Section 21 - Commissioned Processing** | - IAM Least Privilege<br>- Access Transparency<br>- VPC-SC Access Levels |
| **SARB G5/2018 - Cloud Computing** | - Dedicated Interconnect<br>- Private Google Access<br>- Regional Isolation (africa-south1)<br>- CMEK |
| **SARB G4/2022 - Cyber Resilience** | - Security Command Center<br>- Cloud IDS<br>- DLP Scanning<br>- Splunk Integration |
| **PCI-DSS v4.0** | - Hierarchical Firewall Policies<br>- IAM & VPC-SC<br>- Cloud KMS<br>- Security Command Center |

---

> **Document Version**  
> Version 1.0 - Initial Landing Zone Architecture (May 21, 2025)  
> Based on Google Cloud Architecture Framework (2025 Edition)
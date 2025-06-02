# Google Cloud Landing Zone Specification - [Banking Group Name] - Version 2.0
*Date: May 21, 2025*

---

## 1. Executive Summary
This document defines a comprehensive, enterprise-scale Google Cloud Landing Zone for [Banking Group Name], aligned with Google’s Architecture Framework, SARB & POPIA compliance, and global banking security standards. It establishes a repeatable, policy-driven foundation for AI/ML and data-analytics workloads in a hybrid context, integrating with on-prem Active Directory and routing internet egress via on-premises.

Key outcomes and design principles include:
*   **Secure-by-default foundations**: Least-privilege IAM, a single comprehensive VPC Service Control perimeter, Customer-Managed Encryption Keys (CMEK) with Cloud KMS (EKM deferred), Security Command Center (SCC) Standard Tier, and strict network firewall policies.
*   **Modular resource hierarchy**: A refined folder strategy isolating shared services, production, non-production, and sandbox environments, with further segregation by business unit/team.
*   **Resilient hybrid connectivity**: Dual 10Gbps Dedicated Interconnects (Johannesburg), a Global Network Connectivity Center (NCC) Hub in a dedicated transit project, and Shared VPCs in `africa-south1` (primary) and `europe-west2` (London - DR region) acting as NCC spokes, all regions should cater for a production share vps and and nonprod shared vpc. internet egress is hairpinned through on-premises. diagram below illustrates the connectivity model might need updating to show the split between prod and nonprod shared vpc.
*   **Centralized security & compliance**: Policy Controller for policy-as-code, integrated with Security Command Center (SCC) for security insights, and audit logging to on-prem Splunk.
*   **Integrated operations**: Cloud Logging and Monitoring, with critical logs exported to on-prem Splunk for centralized observability.
*   **AI/ML & Data Analytics**: A robust landing pattern for AI/ML and data analytics workloads, leveraging Google Cloud’s data services (Pub/Sub, Dataflow, BigQuery, Vertex AI) within the established security and networking framework.
*   **Automated landing-zone deployment**: Terraform and Cloud Build for CI/CD, with Policy Controller for policy-as-code guardrails and OPA checks in CI.
*   **Centralized Identity**: On-prem Active Directory as the authoritative source, synchronized to Cloud Identity (GCDS), with Azure AD for SAML/OIDC federation. Managed Microsoft AD (MMAD) deployment is deferred but can be optionally included later. Workload Identity Federation is standard for non-human access.
*   **Integrated Operations**: Cloud Logging/Monitoring, with all critical logs exported to on-prem Splunk.

---

## 2. Design Objectives & Key Decisions (Selected Updates)
| Requirement | Decision | Rationale |
|---|-------------|----------|-----------|
| SARB, POPIA, King IV Compliance | `africa-south1` primary region, data-residency controls, single VPC Service Control perimeter for all critical services, CMEK (Cloud KMS), audit logging to on-prem Splunk. `restricted.googleapis.com` for Private Google Access. | Aligns with legislative obligations, enhances data exfiltration protection. |
| Hybrid Connectivity & Resiliency | Dual Dedicated Interconnects (JHB only), Global NCC Hub, Shared VPCs in `africa-south1` & `europe-west2` (London) as NCC spokes. All internet egress via on-prem. | Provides robust, resilient connectivity, centralized traffic control, and leverages Google's backbone for inter-region traffic. |
| Identity Federation & Management | On-prem AD (authoritative) -> GCDS -> Cloud Identity. Azure AD for SAML/OIDC. MMAD deferred. Workload Identity Federation for non-human access. | Maintains existing identity source, modernizes authentication, enhances security for service accounts. |
| Security Monitoring & Policy | SCC Standard Tier. Policy Controller for IaC policy enforcement. Logs to on-prem Splunk. | Provides foundational security insights and automated governance. Integrates with existing SIEM. |

---

## 3. Organization & Resource Hierarchy (Conceptual)
*   **`Organization: bank.example`**
    *   **`Folder: [Shared-Services-Folder-Name]`** (e.g., `00-Shared-Services`)
        *   `Project: [Transit-Connectivity-Project-Name]` (e.g., `prj-c-transit-global-prod`) - Hosts Global NCC Hub, Cloud Routers.
        *   `Project: [Shared-VPC-Host-ZA-Project-Name]` (e.g., `prj-h-sharedvpc-za-prod`) - For `africa-south1`.
        *   `Project: [Shared-VPC-Host-LON-Project-Name]` (e.g., `prj-h-sharedvpc-lon-prod`) - For `europe-west2`.
        *   `Project: [Security-Tools-Project-Name]` (e.g., `prj-c-securitytools-global-prod`) - For SCC, Policy Controller, etc.
        *   `Project: [Logging-Project-Name]` (e.g., `prj-c-logging-global-prod`) - For log sinks to Pub/Sub -> Splunk.
        *   `Project: [Monitoring-Project-Name]` (e.g., `prj-c-monitoring-global-prod`)
        *   *(Placeholder for Risk & Compliance project/sub-folder if distinct from security tools)*
    *   **`Folder: [Prod-Environments-Folder-Name]`** (e.g., `10-Prod-Environments`)
        *   `Folder: [BU-Team-Folder-Prod-Name]` (e.g., `bu-retail-prod`)
            *   `Project: [Workload-Project-Name-Prod]`
    *   **`Folder: [Non-Prod-Environments-Folder-Name]`** (e.g., `20-Non-Prod-Environments`)
        *   `Folder: [BU-Team-Folder-Dev-Name]`
            *   `Project: [Workload-Project-Name-Dev]`
        *   `Folder: [BU-Team-Folder-UAT-Name]`
            *   `Project: [Workload-Project-Name-UAT]`
    *   **`Folder: [Sandbox-Environments-Folder-Name]`** (e.g., `30-Sandbox-Environments`)

*(Specific folder and project names to be finalized internally.)*

---

## 4. Identity & Access Management
*   **Identity Source:** On-prem Active Directory remains authoritative. Synchronized to **Cloud Identity** using **Google Cloud Directory Sync (GCDS)**.
*   **Authentication:** SAML 2.0 / OIDC federation with **Azure AD**.
*   **Authorization:** Group-based IAM roles (from synced AD groups), IAM Conditions, least privilege.
*   **Managed Microsoft AD (MMAD):** Deployment deferred. Landing zone designed to optionally accommodate MMAD in regional Shared VPCs if specific workloads demonstrate a hard requirement.
*   **Workload Identity Federation (WIF):** Standard for non-human access (CI/CD, on-prem services accessing GCP APIs) to avoid service account keys.
*   **Access Boundary Controls:** Single, comprehensive VPC Service Control perimeter protecting all critical Google Cloud services used by the bank. Access into the perimeter governed by context-aware access policies (device compliance via MDM, user identity via specific AD groups).

---

## 5. Networking & Connectivity
*   **Topology Overview:** Hub-and-spoke model using a Global Network Connectivity Center (NCC) Hub.
    *   **NCC Hub:** Single Global NCC Hub deployed in the `[Transit-Connectivity-Project-Name]`.
    *   **On-Prem Connectivity:** Two 10Gbps Dedicated Interconnects (from Johannesburg co-location) connect as VLAN attachments to the NCC Hub. Cloud Routers for BGP reside in the transit project.
    *   **GCP VPC Spokes:** Regional Shared VPCs (`[Shared-VPC-Host-ZA-Project-Name]` in `africa-south1`, `[Shared-VPC-Host-LON-Project-Name]` in `europe-west2`) are attached as spokes to the Global NCC Hub. Dynamic routing mode for Shared VPCs is **Global**.
*   **IP Addressing & BGP:**
    *   GCP Address Range: `10.245.0.0/17` (advertised to on-prem).
    *   On-Prem Address Ranges: Standard RFC1918 (specific supernets advertised to GCP).
    *   Cloud Router ASN: `[YOUR_PRIVATE_ASN]` (placeholder, to be provided).
*   **Internet Egress:** All internet-bound traffic from GCP services is routed via the Interconnects to the on-premises network and egresses through the corporate internet breakout points. No direct internet breakout from GCP.
*   **Access to Google APIs:** Private Google Access configured for subnets using **`restricted.googleapis.com`**.
*   **Firewall:** Hierarchical Firewall Policies applied. Default deny-all egress from VPCs. Tag-based rules for allowed intra-VPC and VPC-to-onprem traffic.

---

## 6. DNS Architecture
*   **Integrated DNS:** Seamless name resolution across GCP and on-premises. Split-horizon DNS is implemented.
*   **GCP Private Zones:** Cloud DNS private zones (e.g., `gcp.bank.example`) associated with regional Shared VPCs.
*   **On-Prem to GCP Resolution:** On-prem BIND servers use conditional forwarding (via Cloud DNS inbound server policies in Shared VPCs) to resolve GCP private zones.
*   **GCP to On-Prem Resolution:** Cloud DNS outbound server policies/forwarding zones in Shared VPCs point to on-prem BIND servers.
*   **Public DNS:** Managed via Cloud DNS public zones (e.g., for `bank.example`).
*   **Future MMAD DNS:** If MMAD is deployed, its zones will be integrated via conditional forwarding from Cloud DNS and on-prem DNS.

---

## 7. Security & Compliance Controls
*   **Data Residency:** Primary: `africa-south1`. DR: `europe-west2` (London).
*   **Encryption:** Default CMEK with Cloud KMS for critical services. Cloud EKM decision deferred.
*   **Workload Isolation:** Single comprehensive VPC Service Control perimeter. Hierarchical firewalls.
*   **Monitoring & Threat Detection:** Security Command Center (SCC) Standard Tier.
*   **Policy Enforcement:** Policy Controller (Anthos Config Management) for policy-as-code.
*   **Regulatory Mapping:** POPIA, SARB, PCI-DSS controls mapped to SCC findings & Policy Controller constraints.
*   **Logging & SIEM:** Cloud Logging exports all critical audit, platform, and application logs via Pub/Sub to on-prem **Splunk**.

---

## 8. AI/ML & Data-Analytics Landing Pattern
*   The pattern outlined in the original specification (Ingestion via Pub/Sub, Dataflow, GCS; Lakehouse with Dataplex, BigQuery; Compute with Vertex AI; MLOps with Cloud Build, Vertex AI Pipelines; Governance with Data Catalog, DLP) remains largely valid.
*   All services will operate within the established VPC Service Control perimeter, network controls (e.g., `restricted.googleapis.com` access), and CMEK encryption.

---

## 9. Hybrid & Multi-Cloud Integration
*   Anthos (GKE on-prem, Anthos Service Mesh) remains the strategic platform for hybrid container workloads and service management, leveraging the NCC-based connectivity.
*   Database Migration Service (DMS) and BigQuery Omni for data integration.
*   Pub/Sub for eventing, potentially bridging to on-prem Kafka if needed.

---

## 10. Operations & Observability
*   **Core Tooling:** Cloud Logging & Cloud Monitoring dashboards.
*   **Alerting:** PagerDuty integration.
*   **APM:** Cloud Trace, Cloud Profiler, OpenTelemetry collector.
*   **Log Management:** All critical logs exported to on-prem Splunk as the SIEM.
*   **FinOps:** BigQuery billing export, Looker Studio dashboards, Recommender API.

---

## 11. Infrastructure as Code & Automation
*   **IaC:** Terraform modules and Cloud Build for CI/CD pipelines.
*   **Policy as Code:** Policy Controller for defining and enforcing organizational policies.
*   **CI/CD Policy Checks:** OPA policy checks integrated into Cloud Build pipelines.
*   **Golden Images:** Packer and OS Config for hardened images; VM Manager for patching.

---

## 12. Cost Management & FinOps
*   Strategies include Committed Use Discounts, BigQuery flat-rate/slots, Storage Lifecycle rules, and real-time budget alerts, as per original spec. These will be applied within the new resource hierarchy.

---

## 13. Implementation Roadmap
*   The phased roadmap (Mobilise, Foundations, Security Baseline, Data & AI Platform, Hybrid Enablement, Go-Live, Continuous Improvement) remains conceptually valid.
*   Timelines and specific milestones will need adjustment to reflect the refined architecture (e.g., NCC setup, transit project).

---
## 14. Appendices
*   (As per original spec - to be developed/updated separately)
    *   A. Service-to-Service Connectivity Matrix
    *   B. Regulatory Control Mapping (SARB, POPIA, PCI DSS)
    *   C. Terraform Module Catalogue
    *   D. Glossary & Abbreviations

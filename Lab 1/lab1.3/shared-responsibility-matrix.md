# AWS Shared Responsibility Model Matrix

**Document Version**: 1.0  
**Date**: October 7, 2025  
**Purpose**: Understanding security and operational responsibilities between AWS and customers  

---

## Overview

The AWS Shared Responsibility Model is a security framework that defines the division of responsibilities between AWS and the customer. AWS operates, manages, and controls the components from the host operating system and virtualization layer down to the physical security of the facilities. Customers are responsible for and manage the guest operating system (including updates and security patches), other associated application software, and the configuration of the AWS-provided security group firewall.

### Key Principles

- **AWS**: "Security OF the Cloud" - Infrastructure, hardware, software, networking, and facilities
- **Customer**: "Security IN the Cloud" - Customer data, platform/applications, identity & access management, operating system, network & firewall configuration

---

## Shared Responsibility Matrix

| Service | AWS Responsibility | Customer Responsibility |
|---------|-------------------|------------------------|
| **EC2 (Elastic Compute Cloud)** | • Physical security of data centers<br>• Host operating system patching<br>• Hypervisor security<br>• Network infrastructure<br>• Hardware maintenance<br>• Power, cooling, and physical access controls | • Guest operating system updates and security patches<br>• Application software and utilities<br>• Security group configuration<br>• Network Access Control Lists (ACLs)<br>• Account management and root access controls<br>• Data encryption (in transit and at rest)<br>• Identity and Access Management (IAM) policies |
| **RDS (Relational Database Service)** | • Database software patching<br>• Operating system patching<br>• Hardware provisioning<br>• Setup, backup, recovery, and failover<br>• Network infrastructure<br>• Physical security<br>• Automated backups and point-in-time recovery | • Database user creation and permissions<br>• Database-level security (users, roles, permissions)<br>• Network security (VPC, security groups)<br>• Data encryption configuration<br>• SSL/TLS configuration<br>• Application-level controls<br>• Database parameter groups configuration |
| **S3 (Simple Storage Service)** | • Infrastructure security<br>• Hardware and software maintenance<br>• Network controls<br>• Host operating system patching<br>• Hypervisor patching<br>• Physical and environmental controls<br>• Service availability and durability | • Bucket policies and Access Control Lists (ACLs)<br>• Data encryption (server-side and client-side)<br>• SSL/TLS for data in transit<br>• Versioning and lifecycle management<br>• Cross-region replication configuration<br>• Logging and monitoring setup<br>• Identity and Access Management (IAM) policies |
| **Lambda (Serverless Computing)** | • Infrastructure security<br>• Operating system maintenance<br>• Runtime environment security<br>• Automatic scaling<br>• Platform patching<br>• Network infrastructure<br>• Physical security | • Function code security<br>• Runtime configuration<br>• Environment variables management<br>• Access permissions (execution roles)<br>• VPC configuration (if applicable)<br>• Data encryption in environment variables<br>• Third-party dependencies security |
| **ECS (Elastic Container Service)** | • Control plane security<br>• Infrastructure management<br>• Host operating system (for EC2 launch type)<br>• Network infrastructure<br>• Physical security<br>• Service availability | • Container images security<br>• Task definitions configuration<br>• IAM roles and policies<br>• Network configuration (VPC, security groups)<br>• Application-level security<br>• Secrets management<br>• Container runtime security |
| **Fargate (Serverless Containers)** | • Infrastructure security<br>• Host operating system<br>• Container runtime environment<br>• Network isolation<br>• Compute resource management<br>• Physical security<br>• Automatic patching and updates | • Container image security<br>• Task definition security<br>• IAM task roles<br>• Network configuration<br>• Application code security<br>• Environment variables and secrets<br>• Resource limits configuration |
| **VPC (Virtual Private Cloud)** | • Physical network infrastructure<br>• Network hardware maintenance<br>• Hypervisor security<br>• Host-level packet filtering<br>• Physical security of network equipment<br>• Availability Zone isolation | • Network Access Control Lists (NACLs)<br>• Security group configuration<br>• Route table management<br>• VPC endpoint configuration<br>• Network segmentation design<br>• VPN and Direct Connect configuration<br>• Flow logs configuration |
| **IAM (Identity and Access Management)** | • Service infrastructure security<br>• Platform availability and durability<br>• Global replication of IAM data<br>• Physical security<br>• Service API security<br>• Compliance certifications | • User creation and management<br>• Role and policy definition<br>• Multi-factor authentication (MFA) setup<br>• Access key rotation<br>• Permission boundaries<br>• Cross-account access configuration<br>• Identity federation setup |
| **CloudFront (Content Delivery Network)** | • Edge location security<br>• Network infrastructure<br>• DDoS protection (basic)<br>• SSL/TLS certificate management (AWS certificates)<br>• Geographic distribution<br>• Physical security of edge locations | • Content security<br>• Origin access configuration<br>• Custom SSL certificates<br>• Cache behavior configuration<br>• Origin shield configuration<br>• WAF integration<br>• Access logging configuration |
| **DynamoDB (NoSQL Database)** | • Hardware provisioning and maintenance<br>• Software patching and updates<br>• Infrastructure security<br>• Backup and restore infrastructure<br>• Global table replication<br>• Physical security | • Table design and data modeling<br>• Access control (IAM policies)<br>• Data encryption configuration<br>• VPC endpoint configuration<br>• Application-level access patterns<br>• Fine-grained access control<br>• Client-side encryption |
| **EBS (Elastic Block Store)** | • Physical storage infrastructure<br>• Hardware maintenance<br>• Network infrastructure<br>• Backup infrastructure (snapshots)<br>• Availability Zone isolation<br>• Physical security | • Data encryption (in transit and at rest)<br>• Access control through EC2 instances<br>• Snapshot management and lifecycle<br>• Volume backup strategy<br>• File system management<br>• Application-level data protection |
| **CloudWatch (Monitoring)** | • Service infrastructure<br>• Metrics collection infrastructure<br>• Log storage infrastructure<br>• API availability<br>• Data durability and availability<br>• Physical security | • Metrics and log configuration<br>• Alert threshold configuration<br>• Dashboard creation<br>• Log group retention policies<br>• Access control (IAM policies)<br>• Custom metrics implementation<br>• Log data encryption |
| **CloudTrail (Audit Logging)** | • Service availability and durability<br>• Log delivery infrastructure<br>• API security<br>• Global service replication<br>• Physical security<br>• Service integrity | • Trail configuration and management<br>• S3 bucket security for log storage<br>• Log file encryption<br>• Access control (IAM policies)<br>• Log file integrity validation<br>• Event selector configuration<br>• Integration with other AWS services |
| **ELB (Elastic Load Balancer)** | • Load balancer infrastructure<br>• Software updates and patching<br>• Network infrastructure<br>• Physical security<br>• Service availability<br>• SSL termination infrastructure | • Target group configuration<br>• Health check configuration<br>• SSL certificate management<br>• Security group configuration<br>• Access logging configuration<br>• Cross-zone load balancing setup<br>• Application-level load balancing logic |
| **Route 53 (DNS Service)** | • DNS infrastructure<br>• Global DNS resolution<br>• Service availability (100% uptime SLA)<br>• Physical security<br>• DDoS protection<br>• Authoritative DNS servers | • Domain registration management<br>• DNS record configuration<br>• Health check configuration<br>• Traffic routing policies<br>• DNS security (DNSSEC)<br>• Access control (IAM policies)<br>• Integration with other AWS services |

---

## Service Categories and Responsibility Patterns

### Infrastructure Services (IaaS)
**Examples**: EC2, VPC, EBS
- **AWS**: Physical infrastructure, hypervisor, host OS
- **Customer**: Guest OS, applications, data, network configuration

### Platform Services (PaaS)
**Examples**: RDS, Lambda, ECS/Fargate
- **AWS**: Infrastructure + platform management
- **Customer**: Application configuration, data, and access management

### Software Services (SaaS)
**Examples**: CloudFront, Route 53, IAM
- **AWS**: Infrastructure + platform + software
- **Customer**: Configuration, data, and access policies

---

## Key Security Considerations by Service Type

### Compute Services (EC2, Lambda, ECS, Fargate)

#### AWS Responsibilities:
- Physical security of compute infrastructure
- Hypervisor and host OS security
- Network infrastructure protection
- Hardware maintenance and replacement

#### Customer Responsibilities:
- Operating system security (EC2)
- Application security across all services
- Identity and access management
- Data encryption and key management
- Network security configuration

### Storage Services (S3, EBS)

#### AWS Responsibilities:
- Physical storage infrastructure
- Hardware redundancy and replacement
- Network storage protocols
- Infrastructure encryption capabilities

#### Customer Responsibilities:
- Data classification and handling
- Access control policies
- Encryption key management
- Backup and disaster recovery planning
- Data lifecycle management

### Database Services (RDS, DynamoDB)

#### AWS Responsibilities:
- Database engine maintenance
- Infrastructure scaling
- Automated backups
- Multi-AZ deployment management

#### Customer Responsibilities:
- Database security configuration
- User access management
- Data encryption setup
- Application-level security
- Database design and optimization

### Networking Services (VPC, CloudFront, ELB)

#### AWS Responsibilities:
- Physical network infrastructure
- Network hardware maintenance
- Basic DDoS protection
- Network service availability

#### Customer Responsibilities:
- Network access controls
- Security group configuration
- Network architecture design
- Application-level security
- Traffic encryption

---

## Compliance and Governance Framework

### AWS Compliance Responsibilities

| Compliance Area | AWS Responsibility | Customer Responsibility |
|-----------------|-------------------|------------------------|
| **Physical Security** | • Data center access controls<br>• Environmental controls<br>• Hardware disposal<br>• Physical monitoring | • Logical access controls<br>• Data classification<br>• Access logging<br>• Incident response |
| **Network Security** | • Network infrastructure<br>• DDoS protection (basic)<br>• Network monitoring<br>• Isolation between customers | • Security groups<br>• NACLs configuration<br>• VPN setup<br>• Application firewalls |
| **Data Protection** | • Infrastructure encryption<br>• Key management service<br>• Backup infrastructure<br>• Data center redundancy | • Data encryption<br>• Key management<br>• Data classification<br>• Access controls |
| **Identity Management** | • IAM service infrastructure<br>• MFA infrastructure<br>• Identity service availability<br>• Global identity replication | • User provisioning<br>• Role management<br>• Access policies<br>• Identity federation |

---

## Best Practices for Each Service

### EC2 Best Practices
**Customer Responsibilities:**
- Keep guest OS and applications updated
- Implement least privilege access
- Use IAM roles instead of access keys
- Enable CloudTrail for API logging
- Configure security groups restrictively
- Encrypt EBS volumes and snapshots

### RDS Best Practices
**Customer Responsibilities:**
- Enable encryption at rest
- Use SSL/TLS for connections
- Implement database user management
- Configure VPC for network isolation
- Enable automated backups
- Monitor database performance and security

### S3 Best Practices
**Customer Responsibilities:**
- Block public access by default
- Enable versioning and MFA Delete
- Use bucket policies and ACLs appropriately
- Enable access logging
- Encrypt data at rest and in transit
- Implement lifecycle policies

### Lambda Best Practices
**Customer Responsibilities:**
- Minimize function privileges
- Encrypt environment variables
- Use VPC when accessing private resources
- Implement proper error handling
- Monitor function performance
- Secure third-party dependencies

---

## Incident Response Responsibilities

### Security Incident Response

| Incident Type | AWS Response | Customer Response |
|---------------|-------------|------------------|
| **Infrastructure Security** | • Immediate infrastructure remediation<br>• Customer notification<br>• Root cause analysis<br>• Infrastructure hardening | • Application impact assessment<br>• Customer data protection<br>• Application-level remediation<br>• Customer notification |
| **Data Breach** | • Infrastructure investigation<br>• Platform security enhancement<br>• Compliance reporting<br>• Customer support | • Data impact assessment<br>• Customer notification<br>• Application security review<br>• Regulatory compliance |
| **Service Outage** | • Service restoration<br>• Root cause analysis<br>• Service credits (if applicable)<br>• Prevention measures | • Application failover<br>• Business continuity<br>• Customer communication<br>• Recovery validation |

---

## Monitoring and Auditing Matrix

### Monitoring Responsibilities

| Service | AWS Monitoring | Customer Monitoring |
|---------|---------------|-------------------|
| **EC2** | • Host infrastructure metrics<br>• Network performance<br>• Hardware health | • Guest OS metrics<br>• Application performance<br>• Security logs<br>• Custom metrics |
| **RDS** | • Database engine health<br>• Infrastructure metrics<br>• Automated backups | • Database performance<br>• Query optimization<br>• Connection monitoring<br>• Security events |
| **S3** | • Service availability<br>• Infrastructure metrics<br>• Request metrics | • Access patterns<br>• Cost optimization<br>• Security events<br>• Data lifecycle |

---

## Conclusion

Understanding the Shared Responsibility Model is crucial for:

1. **Security Posture**: Ensuring comprehensive security coverage
2. **Compliance**: Meeting regulatory requirements
3. **Incident Response**: Clear accountability during incidents
4. **Cost Optimization**: Understanding operational responsibilities
5. **Risk Management**: Proper risk assessment and mitigation

### Key Takeaways:

- **AWS secures the cloud infrastructure** - physical security, network controls, host operating system
- **Customers secure their content in the cloud** - data, applications, access management, network traffic protection
- **Responsibility varies by service type** - IaaS requires more customer responsibility than SaaS
- **Shared services require coordinated security** - both parties must fulfill their responsibilities
- **Documentation and communication** are essential for effective shared responsibility

### Next Steps:

1. Review current implementations against this matrix
2. Identify gaps in customer responsibilities
3. Implement appropriate security controls
4. Establish monitoring and alerting
5. Create incident response procedures
6. Regular review and updates of security posture

---

**Document Owner**: DevOps Security Team  
**Review Frequency**: Quarterly  
**Next Review Date**: January 7, 2026  
**Related Documents**: 
- AWS Security Best Practices Guide
- Incident Response Playbook
- Compliance Checklist
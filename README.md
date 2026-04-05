# 3-Tier-Architecture-By-Using-Terraform
---

## 🧠 Overview

This project builds a **real-world AWS 3-tier architecture using Terraform**.

- 👨‍💻 Users access the application  
- ⚙️ Backend processes requests  
- 🗄️ Database stores data  

👉 Designed for **scalability, security, and high availability**

---

## 🧱 Architecture Flow

User → Public ALB → Public EC2 → Private EC2 → RDS (MySQL)

---

## ⚙️ Step-by-Step Implementation

---

### 1️⃣ Provider Configuration

- Configure AWS provider  
- Region → `us-west-1`  
- Profile → `default`  

---

### 2️⃣ AMI Data Source

- Fetch latest Ubuntu AMI  
- Used for EC2 instances  

---

### 3️⃣ VPC Creation

- CIDR → `10.0.0.0/16`  
- Enable DNS support  
- Enable DNS hostnames  

---

### 4️⃣ Subnet Creation

- Public Subnets:
  - `10.0.1.0/24`
  - `10.0.2.0/24`

- Private Subnets:
  - `10.0.3.0/24`
  - `10.0.4.0/24`
  - `10.0.5.0/24`
  - `10.0.6.0/24`

---

### 5️⃣ Internet Gateway

- Create Internet Gateway  
- Attach to VPC  
- Enables internet access  

---

### 6️⃣ NAT Gateway

- Create NAT Gateway in public subnet  
- Allocate Elastic IP  
- Allows private instances internet access  

---

### 7️⃣ Route Tables

- Public Route Table:
  - `0.0.0.0/0 → Internet Gateway`

- Private Route Table:
  - `0.0.0.0/0 → NAT Gateway`

- Associate route tables with subnets  

---

### 8️⃣ EC2 Instances

- Launch Public EC2 → Web Layer  
- Launch Private EC2 → App Layer  
- Instance type → `t2.micro`  
- AMI → Ubuntu  

---

### 9️⃣ Install NGINX

- Connect to EC2 and run:

sudo -i  
apt update  
apt install nginx -y  
systemctl start nginx  
systemctl enable nginx  

---

### 🔟 Application Load Balancer

- Create Internet-facing ALB  
- Attach public subnets  
- Configure listeners  

---

### 1️⃣1️⃣ Target Group & Listener

- Protocol → HTTP  
- Port → 80  
- Attach EC2 instances to target group  

---

### 1️⃣2️⃣ DB Subnet Group

- Create DB subnet group  
- Use private subnets  

---

### 1️⃣3️⃣ RDS Database

- Engine → MySQL  
- Instance → db.t3.micro  
- Private subnet  
- Disable public access  

---

### 1️⃣4️⃣ Read Replica

- Create read replica  
- Improves performance  
- Provides high availability  

---

# 🚀 Mini DevOps Project – Fullstack App on Azure

This project demonstrates a complete DevOps workflow for deploying a fullstack web application on **Microsoft Azure**, using **Terraform**, **Docker Compose**, and **GitHub Actions** CI/CD.

## 📌 Project Goals

- Provision modular Azure infrastructure using **Terraform**
- Build and orchestrate frontend & backend containers using **Docker Compose**
- Automate deployments via **GitHub Actions**
- Enable multi-environment setup (`dev`, `prod`)
- Ensure resilience, health checks & persistent logging

---

## 📐 Architecture Overview

![Architecture Diagram](./assets/architecture-diagram.png)

**Components:**
- Azure Linux VM (Ubuntu)
- Network interface, NSG, Public IP
- Docker Compose managing:
  - Frontend (React)
  - Backend (Node.js)
- GitHub Actions CI/CD
- Remote Terraform state in Azure Blob
- Healthchecks, reboot handling
- Logging via Docker volumes

---

## 📂 Project Structure

```plaintext
.
├── .github/
│   └── workflows/          # GitHub Actions CI/CD pipelines
├── Terraform/
│   ├── dev/                # Dev environment
│   ├── prod/               # Prod environment
│   └── modules/            # Reusable Terraform modules
├── app/
│   ├── frontend/           # React app
│   ├── backend/            # Node.js API
│   └── docker-compose.yml  # Orchestration config
├── scripts/
│   └── setup_vm.sh         # Bash automation
├── deployment_log.md       # Logged CLI outputs
└── README.md


## Architecture Flow Diagram

## Infrastructure as Code

```

```

## Docker & Compose


## CI/CD Pipeline

## Healthchecks & Automation

## Logging & Documentation

## Resilience Check 

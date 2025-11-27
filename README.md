# EndToEndDeploy: Restaurant Management Portal
**Version:** 1.0.0
**Status:** Active Development

## 1. Overview
The **EndToEndDeploy Restaurant Management Portal** is a full-stack web application designed to facilitate restaurant registration, profile management, and public listing viewing. The system allows restaurant owners to register accounts, authenticate securely, and manage their business details (location, contact info, commercial numbers).

**Key DevOps Considerations:**
* **Containerization:** Fully containerized microservices architecture using Docker.
* **Orchestration:** Deployed on Kubernetes (k3s) for resilience and service discovery.
* **Automation:** Continuous Deployment (CD) pipeline triggers on code commits to build and update the environment.
* **Observability:** Integrated monitoring stack using Prometheus and Grafana.

---

## 2. Architecture

The system utilizes a microservices-based architecture hosted on a single AWS EC2 instance running a lightweight Kubernetes cluster (k3s).

### 2.1 System Architecture Diagram

```mermaid
graph TD
    %% Define nodes first (fixes GitHub strict parsing issues)
    User[Web Browser]
    LB_FE[K8s Service: frontend-service]
    Pod_FE["Frontend Pod (Nginx)"]
    
    LB_BE[K8s Service: backend-service]
    Pod_BE["Backend Pod (Node/Express)"]
    
    Svc_DB[K8s Service: mongo-service]
    Pod_DB[MongoDB Pod]
    PVC["PVC: mongo-pvc"]
    PV["PV: mongo-pv (HostPath)"]

    Prometheus
    NodeExporter
    Grafana

    %% Main flow
    User -->|HTTP:8081| LB_FE
    LB_FE --> Pod_FE

    Pod_FE -->|API Calls HTTP:3001| LB_BE
    LB_BE --> Pod_BE

    Pod_BE -->|TCP:27017| Svc_DB
    Svc_DB --> Pod_DB

    Pod_DB --> PVC
    PVC --> PV

    %% Monitoring section
    subgraph Monitoring ["Monitoring (Docker)"]
        Prometheus -->|Scrape| NodeExporter
        Grafana -->|Query| Prometheus
    end

````

### 2.2 Network Layout

  * **Host:** AWS EC2 (Ubuntu).
  * **Ingress/Access:**
      * **Frontend:** Exposed via LoadBalancer on port `8081` (maps to container port 80).
      * **Backend API:** Exposed via LoadBalancer on port `3001` (maps to container port 3001).
      * **Database:** Internal ClusterIP access only (Port 27017).
  * **Service Discovery:** Kubernetes internal DNS (`mongo-service` resolves to the DB pod IP).

-----

## 3\. Tech Stack & Dependencies

| Layer | Technology | Version | Description |
| :--- | :--- | :--- | :--- |
| **Frontend** | HTML5 / JS / CSS | N/A | Vanilla JS SPA served via Nginx Alpine. |
| **Backend** | Node.js | 18-alpine | Express.js framework with Mongoose ODM. |
| **Database** | MongoDB | Latest | NoSQL Database for storing restaurant profiles. |
| **Auth** | JWT / Bcrypt | ^9.0.2 / ^5.1.1 | JSON Web Tokens for stateless authentication. |
| **Orchestrator**| Kubernetes (k3s) | - | Lightweight K8s distribution. |
| **Registry** | Docker Hub | - | Repository for container images. |
| **OS** | Linux (Ubuntu) | - | Host operating system. |

-----

## 4\. Infrastructure as Code (IaC)

The infrastructure is defined declaratively using Kubernetes Manifests (YAML) and Docker Compose files. There is no usage of Terraform or CloudFormation; the setup relies on a "GitOps-lite" approach where manifests are applied directly from the repo.

### 4.1 Structure

  * `application/k8s/`: Contains Kubernetes manifests.
      * `backend/`: Deployment, Service, ConfigMap.
      * `frontend/`: Deployment, Service.
      * `db/`: Deployment, Service, PV, PVC.
  * `application/monitoring/`: Contains `docker-compose.yml` for the observability stack.

### 4.2 Configuration Management

  * **Environment Variables:** Managed via Kubernetes ConfigMaps (`env-be`).
      * Variables: `MONGODB_URI`, `JWT_SECRET`.
      * **Note:** Secrets are currently stored in plain text within the ConfigMap YAML.

-----

## 5\. CI/CD Pipeline

The project uses **GitHub Actions** for Continuous Integration and Deployment.

**Workflow File:** `.github/workflows/deploy.yml`

### 5.1 Pipeline Stages

1.  **Trigger:** Pushes to the `test` branch.
2.  **Build & Push:**
      * Check out code.
      * Log in to Docker Hub using GitHub Secrets.
      * Build Backend Image -\> Push to `mohamed010/restaurant-backend:latest`.
      * Build Frontend Image -\> Push to `mohamed010/restaurant-frontend:latest`.
3.  **Deploy to EC2:**
      * **SCP:** Copies `application/k8s` and `application/monitoring` directories to the EC2 host (`~/app`).
      * **SSH & Apply:**
          * Executes `k3s kubectl apply` for frontend, backend, and db manifests.
          * Executes `k3s kubectl rollout restart` to force pods to pull the new "latest" images.
          * Executes `docker compose up -d` for the monitoring stack.

### 5.2 Artifacts

  * **Registry:** Docker Hub.
  * **Image Tags:** Currently pinned to `:latest`.

-----

## 6\. Deployment Guide

### 6.1 Prerequisites

  * AWS EC2 Instance (Ubuntu).
  * Installed on Host: `k3s`, `docker`, `docker-compose`.
  * Ports Open (Security Group): 8081 (Frontend), 3001 (API), 3000 (Grafana).

### 6.2 Manual / Local Setup

To run the backend locally without K8s:

```bash
cd application/backend
npm install
# Ensure local MongoDB is running or update .env
npm start
```

### 6.3 Production Deployment

Deployment is automated. To release a new version:

1.  Commit changes to the repository.
2.  Push changes to the `test` branch.
3.  Monitor the "CI/CD - Build, Push, and Deploy to EC2" Action in GitHub.

-----

## 7\. Containerization & Orchestration

### 7.1 Backend

  * **Base Image:** `node:18-alpine` (lightweight, secure).
  * **Ports:** Exposes 3001.
  * **Commands:** Installs dependencies and runs `npm start`.

### 7.2 Frontend

  * **Base Image:** `nginx:alpine`.
  * **Config:** Copies static assets (`.html`, `.css`, `.js`) to `/usr/share/nginx/html`.
  * **Ports:** Exposes container port 80.

### 7.3 Kubernetes Resources

  * **Persistence:** MongoDB uses a `PersistentVolume` backed by `hostPath` (`/mnt/data`) on the node. This ensures data survives pod restarts but ties data to the specific node.
  * **Service Discovery:** The backend connection string uses the K8s DNS name: `"mongodb://mongo-service:27017/restaurant_db"`.

-----

## 8\. Security Hardening

### 8.1 Authentication

  * **JWT (JSON Web Tokens):** Used for protecting API routes (`/restaurants/:id` PATCH/DELETE).
  * **Bcrypt:** Password hashing implemented via Mongoose middleware before saving to DB.
  * **Validation:** `express-validator` sanitizes and validates inputs on the backend.

### 8.2 Current Security Posture & Risks

  * **Risk:** `JWT_SECRET` is stored in a ConfigMap, not a K8s Secret.
  * **Risk:** CORS is enabled globally (`app.use(cors())`).
  * **Risk:** Frontend communicates via HTTP (no SSL/TLS configuration present in Nginx or Ingress).

-----

## 9\. Monitoring & Observability

A sidecar monitoring stack runs via Docker Compose on the same host, independent of the K8s cluster structure but monitoring the node.

  * **Prometheus:** Scrapes metrics every 5 seconds.
      * Targets: `prometheus:9090`, `node-exporter:9100`.
  * **Node Exporter:** Exposes hardware and OS metrics.
  * **Grafana:** Visualization dashboard running on port 3000.
  * **Logging:** Application logs are captured via `morgan` ('dev' format) to stdout, accessible via `kubectl logs`.

-----

## 10\. Testing Strategy

  * **Current Status:** No automated testing suite is currently active in the CI pipeline (`npm test` echoes "no test specified").
  * **Validation:** Input validation logic exists in `routes/restaurant.route.js`.
  * **Recommendation:** Implement Unit Tests (Jest) and Integration Tests before the "Build" stage in GitHub Actions.

-----

## 11\. Backup, Recovery & Failover

  * **Data Persistence:** MongoDB data is stored on the host filesystem at `/mnt/data`.
  * **Failover:**
      * **Compute:** K8s Deployment `replicas: 1`. If the pod crashes, K8s restarts it.
      * **Disaster Recovery:** If the EC2 instance fails completely, data in `/mnt/data` is lost unless an EBS snapshot policy is applied (not visible in current repo).
  * **RPO/RTO:** High risk due to single-node hostPath storage.

-----

## 12\. Known Issues & Future Improvements

### 12.1 Known Issues

1.  **Hardcoded IP:** The Frontend `app.js` has a hardcoded API URL: `const API_BASE_URL = "http://18.205.3.133:3001";`. This requires a code change if the EC2 IP changes.
2.  **Secret Management:** Secrets (`JWT_SECRET`) are committed to the repo in `configmap.yml`.
3.  **Deployment Downtime:** `rollout restart` is used, but with `replicas: 1` and `Recreate` strategy (default if PV is RWO), there may be brief downtime during updates.

### 12.2 Roadmap

  * **Implement SSL:** Add Cert-Manager or Nginx SSL termination.
  * **Dynamic Configuration:** Inject API Base URL into Frontend at runtime (via `config.js` or environment variable substitution).
  * **High Availability:** Increase replica counts and move to a managed DB (MongoDB Atlas) or use a stateful set with proper replication.
  * **IaC Migration:** Move from raw YAML/Shell scripts to Terraform or Helm charts.

-----

## 13\. Appendix: Folder Structure

```text
EndToEndDeploy-main/
├── .github/
│   └── workflows/
│       ├── deploy.yml         # Main CI/CD Pipeline
│       └── docker-publish.yml
├── application/
│   ├── backend/               # Node.js API
│   │   ├── controllers/
│   │   ├── middleware/
│   │   ├── models/
│   │   ├── routes/
│   │   ├── Dockerfile
│   │   └── server.js
│   ├── frontend/              # Nginx + Static Files
│   │   ├── app.js
│   │   ├── index.html
│   │   ├── style.css
│   │   └── Dockerfile
│   ├── k8s/                   # Kubernetes Manifests
│   │   ├── backend/
│   │   ├── db/
│   │   └── frontend/
│   └── monitoring/            # Observability Stack
│       ├── prometheus/
│       └── docker-compose.yml
└── README.md
```

```
```

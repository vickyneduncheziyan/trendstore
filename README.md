# Trendstore DevOps Setup

A CI/CD pipeline for the **Trendstore** app using Jenkins, Kubernetes (EKS), Docker, and Prometheus monitoring.

---

## 🛠️ Tech Stack

- **CI/CD**: Jenkins
- **Containerization**: Docker + DockerHub
- **Orchestration**: AWS EKS (Kubernetes)
- **Monitoring**: Prometheus + kube-state-metrics
- **Source Control**: GitHub

---

## 📁 Repository Structure

```
trendstore/
├── Jenkinsfile
├── deployment.yaml
├── service.yaml
├── Dockerfile
└── (your app code)
```

---

## 🚀 Setup Guide

### Step 1 — Push Files to Git Repo

Add `Jenkinsfile`, `deployment.yaml`, `service.yaml`, and `Dockerfile` to the root of your repository.

---

### Step 2 — Configure Jenkins Credentials

Go to **Jenkins → Manage Jenkins → Credentials → (global) → Add Credential** and add:

| Credential      | Kind                  | ID                     |
|-----------------|-----------------------|------------------------|
| DockerHub       | Username with password | `dockerhub-credentials` |
| GitHub          | Username with password | `github-credentials`   |

> **GitHub PAT**: GitHub → Settings → Developer settings → Personal access tokens → Generate new token → select `repo` scope.

---

### Step 3 — Install Jenkins Plugins

Go to **Jenkins → Manage Jenkins → Plugins → Available** and install:

- Docker Pipeline
- GitHub Integration Plugin
- GitHub Plugin
- Kubernetes CLI Plugin *(optional)*
- Pipeline

Restart Jenkins after installing.

---

### Step 4 — Create EKS Cluster

SSH into your EC2 instance and run:

```bash
eksctl create cluster \
  --name trendstore-cluster \
  --region us-east-1 \
  --nodegroup-name trendstore-nodes \
  --node-type t3.medium \
  --nodes 2 \
  --nodes-min 1 \
  --nodes-max 3 \
  --managed

kubectl get nodes
```

> ⏱️ Cluster creation takes ~15 minutes.

---

### Step 5 — Give Jenkins Access to kubectl

```bash
sudo mkdir -p /var/lib/jenkins/.kube
sudo cp ~/.kube/config /var/lib/jenkins/.kube/config
sudo chown -R jenkins:jenkins /var/lib/jenkins/.kube
sudo usermod -aG docker jenkins
sudo systemctl restart jenkins

# Verify
sudo -u jenkins kubectl get nodes
```

---

### Step 6 — Create Jenkins Pipeline Job

1. Jenkins → **New Item** → name it `trendstore` → choose **Pipeline** → OK
2. Under **Build Triggers** → check ✅ **GitHub hook trigger for GITScm polling**
3. Under **Pipeline** → set Definition to **Pipeline script from SCM**
4. Set SCM to **Git**, Repository URL to `https://github.com/<YOUR_USERNAME>/trendstore.git`
5. Set Credentials to `github-credentials`, Branch to `*/main`, Script Path to `Jenkinsfile`
6. Click **Save**

---

### Step 7 — Set Up GitHub Webhook

Go to your GitHub repo → **Settings → Webhooks → Add webhook**:

| Field         | Value                                     |
|---------------|-------------------------------------------|
| Payload URL   | `http://<EC2_PUBLIC_IP>:8080/github-webhook/` |
| Content type  | `application/json`                        |
| Events        | Just the push event                       |

Click **Add webhook** — you should see a ✅ green tick.

---

### Step 8 — First Manual Deploy

```bash
kubectl apply -f deployment.yaml
kubectl apply -f service.yaml

kubectl get pods
kubectl get svc trendstore-service
```

Access the app at: `http://<ELB_HOSTNAME>:3000`

---

### Step 9 — Test the Full Pipeline

```bash
git add .
git commit -m "test: trigger CI pipeline"
git push origin main
```

This triggers: **webhook → Jenkins → Docker build → DockerHub push → EKS deploy** 🎉

---

## 📊 Monitoring Setup (Prometheus)

Deploy the full monitoring stack:

```bash
kubectl delete namespace monitoring 2>/dev/null
sleep 5
kubectl apply -f prometheus-pod-monitoring.yaml

kubectl wait --for=condition=available --timeout=300s deployment/prometheus -n monitoring
kubectl wait --for=condition=available --timeout=300s deployment/kube-state-metrics -n monitoring

kubectl get pods -n monitoring
```

Get the Prometheus URL:

```bash
kubectl get svc -n monitoring prometheus
# Open: http://<EXTERNAL-IP>:9090
```

### Pod Health Alerts Configured

| Alert           | Condition                            | Severity |
|-----------------|--------------------------------------|----------|
| PodNotRunning   | Pod not in Running/Succeeded state for 2m | Warning |
| PodRestarting   | Pod restarting over last 15m         | Warning  |
| PodNotReady     | Pod not ready for 5m                 | Warning  |

---

## 📋 Quick Reference

| Parameter                     | Value                                      |
|-------------------------------|--------------------------------------------|
| DockerHub repo                | `vickyneduncheziyan/trendstore`            |
| Jenkins credential (Docker)   | `dockerhub-credentials`                    |
| Jenkins credential (GitHub)   | `github-credentials`                       |
| App port                      | `3000`                                     |
| K8s deployment name           | `trendstore`                               |
| K8s service name              | `trendstore-service`                       |
| EKS cluster name              | `trendstore-cluster`                       |
| kubeconfig path (Jenkins)     | `/var/lib/jenkins/.kube/config`            |
| Webhook URL                   | `http://<EC2_IP>:8080/github-webhook/`     |

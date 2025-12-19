---
display_name: New Application Scaffold
description: Scaffold new applications from natural language prompts with Gitea, GitOps, and Argo CD
icon: ../../../site/static/icon/k8s.png
maintainer_github: sirlegendary
verified: true
tags: [scaffold, gitea, gitops, argocd, ai, tasks]
---

# New Application Scaffold

This Coder Task template scaffolds new applications from natural language prompts and deploys them end-to-end.

## What it does

- Accepts a natural language description of your application
- Selects an appropriate framework template (Python, React, Go, etc.)
- Creates a new repository in Gitea under the `demo-apps` organisation
- Generates application code, documentation, Dockerfile, and deployment manifests
- Sets up GitOps configuration for Argo CD
- Triggers CI to build and push the container image to Gitea Container Registry
- Deploys the app to its own namespace in the cluster

## Prerequisites

- Gitea with container registry enabled
- Argo CD installed and configured
- Base application templates in Gitea (e.g., `platform-app-templates`)
- OpenAI API key configured as a Kubernetes secret
- Cluster ingress available for application URLs

## Usage

1. Run this task from Coder Tasks
2. Provide a prompt describing your application, for example:
   > "Create a Python Flask web application with a landing page and contact form"
3. The task will scaffold the entire application and report back with:
   - Gitea repository URL
   - Namespace name
   - Expected application URL
   - Next steps for iterative development

## After scaffolding

Create a Coder workspace using the appropriate workspace template and attach it to the new repository to continue development.

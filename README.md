# MCP with OpenShift - OcpSandbox Deployment

Ansible collection for deploying MCP with OpenShift lab on shared pre-provisioned clusters using the OcpSandbox (namespace) model.

## Architecture

This lab uses two deployment stages:

### Cluster Provisioning (shared infra, run once per cluster)

Playbook: `tests/e2e/cluster-provision.yml`

Deploys shared infrastructure on a fresh OCP cluster. No per-user resources.

| Step | Role/Resource | What It Does |
|------|--------------|-------------|
| 1 | `agnosticd.core_workloads.ocp4_workload_authentication_keycloak` | RHBK operator + OAuth provider |
| 2 | `agnosticd.core_workloads.ocp4_workload_gitea_operator` | Gitea instance (admin only, no users) |
| 3 | `agnosticd.core_workloads.ocp4_workload_pipelines` | OpenShift Pipelines (Tekton) |
| 4 | `agnosticd.core_workloads.ocp4_workload_openshift_gitops` | ArgoCD (no per-user access) |
| 5 | `agnosticd.ai_workloads.ocp4_workload_toolhive` | ToolHive operator |
| 6 | ConfigMap `cluster-monitoring-config` | User workload monitoring |
| 7 | Subscription `cloudnative-pg` | CloudNativePG operator |

### User Provisioning (per-user, run on each lab order)

Playbook: `tests/e2e/provision.yml`
AgV catalog: `agd_v2/mcp-with-openshift-sandbox/common.yaml`

Deploys per-user resources via `config: namespace` pattern. Each role's `main.yml` dispatches to `workload.yml` (provision) or `remove_workload.yml` (destroy) based on the `ACTION` variable.

**Provision order (`workloads`):**

| Step | Role | What It Does |
|------|------|-------------|
| 1 | `agnosticd.namespaced_workloads.ocp4_workload_ocpsandbox_keycloak_user` | Kubeconfig + cluster discovery + Keycloak user |
| 2 | `agnosticd.namespaced_workloads.ocp4_workload_ocpsandbox_gitea_user` | Gitea user + repo migration |
| 3 | `agnosticd.namespaced_workloads.ocp4_workload_ocpsandbox_argocd_user` | ArgoCD AppProject |
| 4 | `rhpds.litellm_virtual_keys.ocp4_workload_litellm_virtual_keys` | LLM API key |
| 5 | `rhpds.ocpsandbox_mcp_with_openshift.ocp4_workload_ocpsandbox_mcp_user` | MCP servers + LibreChat + Agent |
| 6 | `agnosticd.showroom.ocp4_workload_showroom_ocp_integration` | Console links |
| 7 | `agnosticd.showroom.ocp4_workload_showroom` | Showroom lab content |

**Destroy order (`remove_workloads`):** reverse of above -- Showroom first, keycloak_user last.

## Roles in This Collection

| Role | Scope |
|------|-------|
| `ocp4_workload_ocpsandbox_mcp_user` | **User provisioning.** Single-user MCP deployment: SCC + 5 ArgoCD ApplicationSets (mcp-openshift, mcp-gitea, librechat-config, librechat, agent). Full cleanup on destroy. |

## Related Repos

| Repo | Purpose |
|------|---------|
| [ocpsandbox-mcp-with-openshift-gitops](https://github.com/rhpds/ocpsandbox-mcp-with-openshift-gitops) | Helm charts deployed by ArgoCD (user provisioning) |
| [namespaced_workloads](https://github.com/agnosticd/namespaced_workloads) (branch `namespace-mcp-with-openshift`) | Generic sandbox roles: keycloak_user, gitea_user, argocd_user (user provisioning) |
| [lb1726-mcp-showroom](https://github.com/rhpds/lb1726-mcp-showroom) | Showroom lab content |

## E2E Testing

```bash
cd tests/e2e

# Set cluster credentials in cluster-provision.yml / provision.yml
# Then run:
./run.sh cluster-provision -v   # Shared infra (run once)
./run.sh provision -v           # Per-user resources
./run.sh destroy -v             # Cleanup per-user resources
```

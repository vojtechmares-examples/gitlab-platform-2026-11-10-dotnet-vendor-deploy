# dotnet-vendor-deploy

The **in-house deployment repository** for `dotnet-vendor`, an application whose source code is delivered by a vendor
([`dotnet-vendor`](../dotnet-vendor)). The vendor publishes container images; this repository decides which version runs
where.

| Topic | How |
|-------|-----|
| What is deployed | one **Podman Quadlet** per environment: `quadlet/<env>/dotnet-vendor-<env>.container` (the image tag is on the `Image=` line) |
| How it runs | rootless Podman as the account `svc-dotnet`; systemd's Quadlet generator turns the file into `dotnet-vendor-<env>.service` of that user's systemd instance (lingering, so it survives logouts and reboots) |
| Release | a merge request that changes the tag, for example `1.0.0` -> `1.1.0` |
| **Approvals** | `.gitlab/CODEOWNERS` names **vojtech.mares** as the required approver; "main" is protected, nobody pushes to it, and merging needs the code owner's approval *(Premium)*. The `production` environment is protected as well, and a deployment there needs an approval *(Premium)* |
| Pipeline | `validate` checks the Quadlet files with Podman's own generator (in merge requests too); `deploy:staging` runs on `main`; `deploy:production` is manual |
| Registry access | the vendor's read-only deploy token is kept in the CI/CD variables `VENDOR_REGISTRY_USER` / `VENDOR_REGISTRY_TOKEN` and written to `~/.config/containers/auth.json` on the server |
| HTTPS | Caddy: https://dotnet-vendor-staging.examples.maresdemo.com, https://dotnet-vendor-production.examples.maresdemo.com |

## CI configuration

The pipeline reads the CI/CD variables below (*Settings > CI/CD > Variables*). Variables that start with `CI_` are predefined by GitLab.

| Variable | Set on | Type | Used for |
|----------|--------|------|----------|
| `DEPLOY_HOST` | group `examples` | Variable | Address of the deploy server |
| `DEPLOY_SSH_PORT` | group `examples` | Variable | SSH port of the deploy server (`6022`) |
| `DEPLOY_USER` | group `examples` | Variable | Account the pipelines log in as (`deploy`); not used here, see `SSH_USER` below |
| `SSH_KNOWN_HOSTS` | group `examples` | Variable | Host keys of the deploy server; the connection uses `StrictHostKeyChecking yes` |
| `SSH_PRIVATE_KEY` | group `examples` | File, **protected** | Private key of the `deploy` account. Its public key is authorised for `svc-dotnet` by the `ansible` project (`DEPLOY_PUBLIC_KEY`) |
| `EXAMPLES_DOMAIN` | group `examples` | Variable | Parent domain of the applications (`examples.maresdemo.com`); `scripts/deploy.sh` waits for `https://dotnet-vendor-<env>.$EXAMPLES_DOMAIN` |
| `VENDOR_REGISTRY_USER` | this project | Variable | User name of the read-only deploy token `dotnet-vendor-deploy-pipeline` of the `dotnet-vendor` project |
| `VENDOR_REGISTRY_TOKEN` | this project | Variable, **masked**, **protected** | The token itself (scope `read_registry`). `scripts/deploy.sh` writes both to `~/.config/containers/auth.json` of `svc-dotnet` on the server so that Podman can pull the vendor's images |

`SSH_USER` is set in `.gitlab-ci.yml` (`svc-dotnet`), not in the UI: the jobs log in as the rootless Podman account, and `.ssh-setup` of `examples/ci-templates` uses `SSH_USER` when it is set and `DEPLOY_USER` otherwise. It is a separate name because a `variables:` entry of the file cannot override a group variable of the same name.
The group variables are inherited by every project in the `examples` group. A **protected** variable is passed only to pipelines on protected branches and tags (`main`), which is where the deploy jobs run; the `validate` job in merge requests needs none of them.

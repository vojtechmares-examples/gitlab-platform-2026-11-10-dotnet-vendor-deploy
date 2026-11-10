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

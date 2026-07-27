# Upgrading the MapLarge Helm Chart

## v3.x → v4.0

Version 4.0 is a major release: it introduces strict values validation, splits the
Service configuration, moves the container to an unprivileged port, and hardens the
default security posture. Several changes require values updates before upgrading.

The fastest migration path: point your existing values at the new chart and run

```bash
helm template <release> <chart> -f your-values.yaml
```

The chart now ships a `values.schema.json`, so every stale or renamed key is reported
by name before anything reaches the cluster. Fix what it lists, re-run, repeat until
clean.

---

### Breaking changes

#### 1. Values are now schema-validated (strict)

The chart validates all values against `values.schema.json` during `helm lint`,
`template`, `install`, and `upgrade` — including the render ArgoCD performs. Unknown
top-level keys, removed keys, and type errors are rejected with explicit messages
instead of being silently ignored.

Notable constraints that may catch existing values files:

| Constraint | Detail |
|---|---|
| Unknown keys rejected | Typos and removed values fail validation (`additionalProperties: false`) |
| `image.pullPolicy` | Must be `Always`, `IfNotPresent`, or `Never` |
| `environmentVariables[]` / `extraEnvironmentVariables[]` | Each entry requires `name` |
| `ingress.hosts[]` | `baseHostname` required; only `baseHostname`, `prefixes`, `tls` allowed |
| `listenPort` | Integer, 1024–65535 (see §3) |

> **ArgoCD note:** schema failures surface as a render/comparison error on the
> Application *before* any sync — the running release is untouched. Make sure no
> Application sets `spec.source.helm.skipSchemaValidation: true`, which disables
> this guardrail.

#### 2. `service` split into `headlessService` and `loadBalancerService`

The two Service resources are now configured independently, and the container listen
port has moved to a top-level value:

**Before (v3.x):**
```yaml
service:
  targetPort: 80
  annotations: {}        # applied to BOTH services
```

**After (v4.0):**
```yaml
listenPort:              # container listen port; unset = 8080 (8443 when tls.enabled)

headlessService:
  annotations: {}        # cluster-DNS (headless) Service only

loadBalancerService:
  port:                  # in-cluster exposed port; unset = 80 (443 when tls.enabled)
  annotations: {}        # load balancer Service only

tls:
  enabled: false         # see "TLS support" under New in 4.0
```

`listenPort` drives the `ML_LISTEN_PORT` environment variable, the containerPort,
the headless Service port, and the generated `cluster.json` URLs — one knob, no
drift. The ingress references the load balancer port by *name* (`web`), so changing
`loadBalancerService.port` requires no ingress changes.

#### 3. Default listen port changed from 80 to 8080

The container now runs as non-root without `NET_BIND_SERVICE` (see §4) and cannot
bind privileged ports; the schema enforces `listenPort >= 1024`. The chart tells the
app which port to use via `ML_LISTEN_PORT` — no image configuration needed.

External contracts are unchanged: the load balancer Service still exposes port 80
in-cluster, and the ingress is unaffected.

> **Upgrade behavior:** a listen port (or scheme) change breaks the cluster mesh
> during a rolling update — old and new pods advertise different addresses. The
> pre-upgrade hook detects this by comparing the live StatefulSet's container
> port/name against the incoming values and automatically performs a full restart
> (scale to 0, wait, then upgrade), the same way it already handles version
> mismatches. This applies when the hook is enabled and `replicas > 1`; if you
> run with `hooks.preUpgradeHook.enabled: false`, plan the full restart manually
> in a maintenance window.

#### 4. Hardened security defaults

`podSecurityContext` and `securityContext` previously defaulted to `{}`. They now
default to a hardened profile:

```yaml
podSecurityContext:
  runAsNonRoot: true
  runAsUser: 10001
  runAsGroup: 10001
  fsGroup: 10001
  seccompProfile:
    type: RuntimeDefault

securityContext:
  allowPrivilegeEscalation: false
  readOnlyRootFilesystem: true
  capabilities:
    drop: ["ALL"]
```

A writable `emptyDir` is mounted at `/tmp`; `App_Data` remains the PVC. To opt out
(e.g. cluster policy conflicts), set either value to `{}` explicitly.

> **Existing volumes:** data previously written by root must become readable by UID
> 10001. Kubernetes applies `fsGroup` ownership on mount; on large `App_Data`
> volumes the recursive chown can slow the first pod start. To only re-own when
> needed, add `fsGroupChangePolicy: "OnRootMismatch"` to `podSecurityContext`.

#### 5. LTE service removed

The `lteservice.yaml` template and all `lte.*` values are gone. Any `lte:` block in
a values file now fails validation. If you relied on the LTE LoadBalancer, recreate
it via `extraObjects`.

#### 6. `tolerations` type changed from object to array

`tolerations` must now be a YAML list, matching the Kubernetes spec. The previous
`{}` type was incorrect and made the field unusable.

```yaml
# Before:            After:
tolerations: {}      tolerations: []
```

#### 7. Headless Service port now equals the listen port

The headless Service previously declared port 80 regardless of the container port.
Headless Services do not remap ports — pods are reached directly on the container
port — so the declared port now follows `listenPort`. Anything resolving pod DNS
through the headless service and assuming port 80 must use `listenPort` instead
(the generated `cluster.json` already does).

#### 8. MapLarge-internal defaults removed

The following defaults were specific to MapLarge's own infrastructure and have been
removed. If you relied on them, set them explicitly:

| Value | Old default | New default | Action if you relied on it |
|---|---|---|---|
| `image.repository` | `docker.io/maplarge/server-netcore-dev` | `docker.io/maplarge/server` | Set the dev repository explicitly if you want dev builds |
| `image.tag` | `latest` | `""` → `release-core-<appVersion>` from Chart.yaml | Pin your own tag, or leave empty for the chart-tested release |
| `image.pullSecretName` | `maplarge-dockerhub-pull-secret` | `""` (no pull secret) | Set your pull secret name |
| `appDataVolumeStorageClassName` | `openebs-hostpath` | renamed: `storage.storageClass`, unset (cluster default class) | Set your storage class under the new key |
| `appDataVolumeSizeInGB` | `100` | renamed: `storage.size` (still 100) | Move the value to the new key |
| `ingress.hosts[0].baseHostname` | `customer-a.dev.maplarge.net` | `maplarge.example.com` | Set your hostname (you almost certainly already do) |
| `ingress.hosts[0].tls` | enabled, MapLarge wildcard secret | disabled, no secret | Set your TLS secret |
| `requireNodeAntiAffinity` | `true` | `false` | Set `true` explicitly for production spread guarantees |
| `jsjs.value` | nested string | flattened: `jsjs` is now the string itself | Move the content up one level: `jsjs: \|` |
| `useTransactionalDatabase` | `true` (set `ML_USE_TRANSACTIONAL_DATABASE`) | removed — the chart no longer sets the env var; the app default applies | Add `ML_USE_TRANSACTIONAL_DATABASE` to `environmentVariables` if you need it pinned |

Also removed: the chart no longer sets `ML_REPL_ENABLED` (v3 hardcoded it to
`"false"`). If your deployment depends on it being explicitly set, add it to
`environmentVariables`.

Related fix: when `storage.storageClass` is unset, the PVC template now
**omits** `storageClassName` entirely (using the cluster default). Previously an
unset value rendered `storageClassName: ""`, which disables dynamic provisioning.

#### 9. `dockerCredentials` removed — the chart no longer creates pull secrets

Putting registry credentials in Helm values embeds them in release manifests,
GitOps repos, and rendered output, so the `dockerCredentials` value and the
Secret it generated are gone. Create the pull secret out-of-band and reference
it by name:

```bash
kubectl create secret docker-registry my-pull-secret \
  --docker-server=... --docker-username=... --docker-password=...
```

```yaml
image:
  pullSecretName: my-pull-secret
```

For a GitOps-friendly path, manage the secret with your secrets operator (e.g.
an `ExternalSecret` via `extraObjects`).

#### 10. Hostname env vars decoupled from the ingress

`ML_CLIENT_CONFIG_SERVER_HOSTNAME` and `ML_CLIENT_CONFIG_PREFIX_COUNT` were only
rendered when `ingress.enabled: true`. They now render whenever a hostname is
derivable — from `hostnameOverride` or `ingress.hosts[0]` — even with the ingress
disabled. This supports platforms that manage ingress outside the chart. If you run
with the ingress disabled and need these env vars absent, remove `ingress.hosts`
(`ingress.hosts: null`) and leave `hostnameOverride` unset.

---

### New in 4.0 (no action required)

- **TLS support (`tls.enabled`):** when the MapLarge container is configured to
  serve HTTPS, setting `tls.enabled: true` makes the chart follow suit end to end:
  listen port defaults to 8443 (load balancer Service port 443), container/Service
  ports are named `https` so service meshes detect the protocol, inter-node
  `cluster.json` URLs use `https://`, and all probes switch to HTTPS. Probe
  `httpGet.port`/`httpGet.scheme` can still be set explicitly to override the
  derived values. Note the app itself must be configured to serve TLS (certificate
  loading is app configuration, not chart configuration), and an ingress in front
  of a TLS backend needs its controller's backend-protocol annotation.
- **Previously hardcoded env vars now configurable** (defaults preserve v3
  behavior): `corsEnabled: true` (`ML_CLIENT_CONFIG_ENABLE_CORS`),
  `corsAllowedOrigins: "%"` (`ML_CORS_ALLOWED_ORIGINS`).
- **Generated schema + docs:** `values.schema.json` is generated from `# @schema`
  annotations in `values.yaml` (config in `.schema.yaml`, regenerate with
  `helm schema`); CI keeps it and the README current.
- **Previously hidden values documented:** `nameOverride`, `fullnameOverride`,
  `team`, `extraEnvironmentVariables`, `extraObjects`, `defaultClusterName`,
  `numberOfAutoJoinMembers`, `headlessServiceName`, `configurationDirectory`,
  `initContainerImage` are now in `values.yaml` and the schema.
- **Security scanning:** the chart passes `trivy config` apart from documented,
  justified waivers in `.trivyignore` (scan with
  `--ignorefile charts/maplarge/.trivyignore`).

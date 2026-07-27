# MapLarge

MapLarge Kubernetes Helm Chart

![Version: 4.0.0](https://img.shields.io/badge/Version-4.0.0-informational?style=flat-square) ![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square) ![AppVersion: 4.135](https://img.shields.io/badge/AppVersion-4.135-informational?style=flat-square)

## Additional Information

This helm chart will deploy MapLarge, but does require some input for a successful installation. We recommend creating a custom values file to manage the overrides that are needed for your environment. Use this file to deploy the chart.

## Requirements

Kubernetes: `>= 1.19.0-0`

## Licensing

There are two ways to install the MapLarge license with the chart:

1. Create a secret with the license file, and a key of `_maplarge_license.lic` and provide the name of the secret to `.Values.license.existingSecretName`

```console
kubectl create secret generic maplarge-license --from-file=_maplarge_license.lic=/path/to/_maplarge_license.lic
```

1. Provide the content of the license file to `.Values.license.license` and the helm chart will generate the secret

## Installing the Chart

To install the chart with the release name `maplarge`:

```console
$ helm repo add maplarge https://maplarge.github.io/helm-charts
$ helm install maplarge maplarge -f custom.values.yaml
```

## Values

### MapLarge Configuration

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| authPlugin.enabled | bool | `false` | Determines if the authPlugin should be enabled |
| authPlugin.filename | string | `nil` | Specifices the path in the container where the authPlugin configuration file can be found. Can be left blank. |
| authPlugin.typeName | string | `nil` | Specifies the MapLarge authPlugin to use |
| config | object | `nil` | Allows for custom configurations for the MapLarge config.json. |
| corsAllowedOrigins | string | `"%"` | Allowed CORS origins (sets ML_CORS_ALLOWED_ORIGINS) |
| corsEnabled | bool | `true` | Enables CORS in the MapLarge client config (sets ML_CLIENT_CONFIG_ENABLE_CORS) |
| environmentVariables | list | `[{"name":"ML_STDERR_LOG_LEVEL","value":"2"},{"name":"ml_cfg_homepageRedirect","value":"dashboard"}]` | A map of extra environment variables to be added to the MapLarge container |
| existingRootPasswordSecretName | string | `nil` | An existing secret that contains a value that will be used as the root password; the key must be set to `rootPassword` |
| extraEnvironmentVariables | list | `[]` | A second list of extra environment variables to be added to the MapLarge container, merged after environmentVariables |
| jsjs | string | `nil` | Allows for custom configurations for the js.js. This value is read in as-is, so each js.js option needs to be on it's own line. |
| rootPassword | string | `nil` | If set, the root password will be set according to this value, otherwise a default value is created |
| rootPasswordSecretName | string | `nil` | If set, defines the name of the secret for the root password |

### General

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| clusterConfig | object | `nil` | Extra configuration options for cluster.json. Keys set here win over the chart-generated defaults. When replicas < 3, the chart defaults ChangeSetReplicationFactor to 1 so MapLarge does not warn about unmet replication criteria; set it here to override. |
| extraLabels | map | `{}` | extraLabels Extra labels to apply to all resources |
| extraObjects | list | `[]` | A list of extra Kubernetes manifests to render. Entries may be objects or strings; strings are passed through tpl for templating. |
| extraVolumeMounts | list | `[]` | extraVolumeMounts Specify any extra list of additional volumeMounts for MapLarge |
| extraVolumes | list | `[]` | extraVolumes Specify any extra list of additional volumes for MapLarge |
| fullnameOverride | string | `nil` | Overrides the fully qualified app name used to name resources |
| headlessService.annotations | object | `{}` | Annotations to be added to the headless (cluster DNS) Service |
| listenPort | string | `nil` | The port the MapLarge container listens on. The chart passes it to the app via ML_LISTEN_PORT and uses it for the container port, the headless Service port, and cluster.json URLs. When unset, defaults to 8443 if tls.enabled is true, otherwise 8080. Must be >= 1024: the container runs as non-root without NET_BIND_SERVICE, so it cannot bind privileged ports. |
| loadBalancerService.annotations | object | `{}` | Annotations to be added to the load balancer Service |
| loadBalancerService.port | string | `nil` | The in-cluster port the load balancer Service exposes. When unset, defaults to 443 if tls.enabled is true, otherwise 80. The ingress references this port by name, so changing it requires no ingress changes. |
| nameOverride | string | `nil` | Overrides the chart name used to name resources |
| nodeAffinityPreferences | list | `[]` | Sets the node affinity preferences for the MapLarge pod |
| nodeAffinityRequirements | list | `[]` | Sets the nodeAffinityRequirements for the pod |
| nodeSelector | object | `{}` | Sets the node selector for the MapLarge pod |
| podAnnotations | object | `{}` | podAnnotations Extra annotations to add to your pods' metadata. Usually unnecessary. |
| podSecurityContext | object | `{"fsGroup":30102,"fsGroupChangePolicy":"OnRootMismatch","runAsGroup":30102,"runAsNonRoot":true,"runAsUser":30101,"seccompProfile":{"type":"RuntimeDefault"}}` | Sets the podSecurityContext. Defaults run the pod as a non-root user with a RuntimeDefault seccomp profile. Set to {} to fall back to cluster defaults. |
| preferNodeAntiAffinity | bool | `true` | Set to true if you want to prefer that your replicas are placed on distinct nodes. |
| replicas | int | `3` | replicas The number of replicas to create in the StatefulSet. Defaults to 1. |
| requireNodeAntiAffinity | bool | `false` | Set to true if you want to REQUIRE that your replicas are placed on different nodes. Recommended for production; left off by default so small/single-node clusters can schedule all replicas. |
| securityContext | object | `{"allowPrivilegeEscalation":false,"capabilities":{"drop":["ALL"]},"readOnlyRootFilesystem":true}` | Sets the container securityContext. Defaults block privilege escalation, drop all capabilities, and mount the root filesystem read-only (/tmp is an emptyDir; App_Data is the PVC). Set to {} to fall back to cluster defaults. |
| serviceAccount.annotations | object | `{}` | Specifies Service Account specific Annotations |
| serviceAccount.create | bool | `false` | Specificies whether a service account should be created. If the deploying user does not have permissions to create an SA, then this value should be set to false. |
| serviceAccount.name | string | `""` | To use an existing service account, provide the name here. If not set and create is true, a name is generated using the maplarge.name template. |
| simpleNodeAffinityPreferences | list | `[]` | Sets simple node affinity preferences for the MapLarge pod |
| simpleNodeAffinityRequirements | list | `[]` | Sets the simpleNodeAffinityRequirements for the pod |
| simpleTolerations | list | `[]` | Sets a simple toleration for the MapLarge pod |
| team | string | `nil` | When set, adds team ownership labels (maplarge.com/project, team, app.kubernetes.io/owner) to all resources |
| tls.enabled | bool | `false` | Set to true if the MapLarge container is configured to serve HTTPS. The chart then defaults the listen port to 8443 (Service port 443), names ports https so meshes detect the protocol, uses https for inter-node cluster communication, and probes over HTTPS. The app itself must be configured to serve TLS; this is distinct from ingress.hosts[].tls, which controls TLS at the ingress edge. |
| tolerations | list | `[]` | Sets the tolerations for the MapLarge pod |

### Docker configurations

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| dockerCredentials | object | `{}` | this will create your pull secret for you. Required fields are registry, username, password, and email |

### Hooks

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| hooks.preUpgradeHook | object | `{"enabled":true,"image":{"repository":"bitnami/kubectl","tag":"latest"}}` | Enables pre-upgrade hook to ensure proper upgrade procedure for DB binary format revisions |
| hooks.preUpgradeHook.image.repository | string | `"bitnami/kubectl"` | The image repository to use for the pre-upgrade hook job |
| hooks.preUpgradeHook.image.tag | string | `"latest"` | The image tag to use for the pre-upgrade hook job. |

### Ingress Configuration

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| hostnameOverride | string | `nil` | Rarely there is a time when you need to set the MapLarge hostname to something other than the ingress hostname, but if you do have that scenario, you can provide a hostname here to override the value that will be derived from the ingress.hosts[0].basehostname. Note, this does not modify the ingress hostname value. |
| ingress.annotations | object | `{}` | Annotations to set on the ingress object. No annotations are set by default; add any ingress controller-specific annotations here as needed. |
| ingress.class | string | `""` | Ingress class to use. If not set, no ingressClassName will be set on the resource. |
| ingress.enabled | bool | `true` | Enable ingress object |
| ingress.hosts[0] | object | `{"baseHostname":"maplarge.example.com","prefixes":8,"tls":{"enabled":false,"secretName":null}}` | Custom DNS name where MapLarge can be reached |
| ingress.hosts[0].prefixes | int | `8` | The number of dns prefixes to create |
| ingress.hosts[0].tls.enabled | bool | `false` | Controls if the site is TLS protected |
| ingress.hosts[0].tls.secretName | string | `nil` | The TLS secret to use if TLS protected |

### Image Information

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| image.extraPullSecrets | list | `[]` | An array of any extra image pull secrets to add to the pod definition, in |
| image.pullPolicy | string | `"IfNotPresent"` | Image pull policy |
| image.pullSecretName | string | `""` | Secret to create or use to pull the docker image from the registry. Leave empty if the cluster can pull without one. |
| image.repository | string | `"docker.io/maplarge/server"` | The fully qualified repository where the MapLarge image should be pulled from |
| image.tag | string | `""` | The MapLarge image tag to pull. When empty, defaults to the release tag for the chart's appVersion (release-core-<appVersion>). |

### License

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| license.annotations | object | `{}` | Annotations to set on the license secret |
| license.existingSecretName | string | `""` | A secret name for an existing license secret. If creating your own license secret, the key must be "_maplarge_license.lic" |
| license.license | string | `""` | The content of the MapLarge license if one has been provided to you |

### Probe Configurations

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| livenessProbe.failureThreshold | int | `6` | Failure threshold for livenessProbe |
| livenessProbe.httpGet.path | string | `"/Cluster/IsAlive"` | Endpoint for the livenessProbe |
| livenessProbe.initialDelaySeconds | int | `0` | Initial delay seconds for livenessProbe |
| livenessProbe.periodSeconds | int | `5` | Period seconds for livenessProbe |
| livenessProbe.successThreshold | int | `1` | Success Threshold for livenessProbe |
| livenessProbe.timeoutSeconds | int | `2` | Timeout seconds for livenessProbe |
| readinessProbe.failureThreshold | int | `3` | Failure threshold for readinessProbe |
| readinessProbe.httpGet.path | string | `"/Cluster/IsReadyForUser"` | Endpoint for the readinessProbe |
| readinessProbe.initialDelaySeconds | int | `0` | Initial delay seconds for readinessProbe |
| readinessProbe.periodSeconds | int | `5` | Period seconds for readinessProbe |
| readinessProbe.successThreshold | int | `2` | Success Threshold for readinessProbe |
| readinessProbe.timeoutSeconds | int | `2` | Timeout seconds for readinessProbe |
| startupProbe.failureThreshold | int | `360` | Failure threshold for startupProbe |
| startupProbe.httpGet | object | `{"path":"/Cluster/IsReady"}` | Endpoint for the startup probe |
| startupProbe.periodSeconds | int | `10` | Period seconds for startupProbe |

### Notebook configurations

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| notebooks.enabled | bool | `false` | Enables MapLarge Notebooks and creates the necessary Service Account, Role and RoleBinding |

### Deployment Resources

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| resources.limits.cpu | int | `4` | The CPU Limit to set for the pod |
| resources.limits.memory | string | `"8Gi"` | The Memory Limit to set for the pod |
| resources.requests.cpu | int | `1` | The CPU Request to set for the pod |
| resources.requests.memory | string | `"4Gi"` | The Memory Request to set for the pod |

### Storage Information

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| storage.size | int | `100` | Defines the size of the PVC to be attached. Values are in GB |
| storage.storageClass | string | `nil` | Requested storage class name. When unset, the cluster's default storage class is used. |

----------------------------------------------
Autogenerated from chart metadata using [helm-docs v1.14.2](https://github.com/norwoodj/helm-docs/releases/v1.14.2)

## Maintainers

| Name | Email | Url |
| ---- | ------ | --- |
| MapLarge DevOps | <maplarge.devops@maplarge.com> |  |

---

To regenerate this README, run

```
docker run --rm --volume "$(pwd):/helm-docs" -u $(id -u) jnorwood/helm-docs:latest
```
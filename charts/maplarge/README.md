# MapLarge

MapLarge Kubernetes Helm Chart

![Version: 3.3.3](https://img.shields.io/badge/Version-3.3.3-informational?style=flat-square) ![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square) ![AppVersion: maplarge](https://img.shields.io/badge/AppVersion-maplarge-informational?style=flat-square)

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

### Storage Information

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| appDataVolumeSizeInGB | int | `100` | appDataVolumeSizeInGB Requested size of PVC to be created. @schema required: true type: number @schema |
| appDataVolumeStorageClassName | string | `""` | appDataVolumeStorageClassName Requested storage class name. @schema required: true @schema |

### MapLarge Configuration

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| authPlugin.enabled | bool | `false` | Determines if the authPlugin should be enabled |
| authPlugin.filename | string | `""` | Specifies the path in the container where the authPlugin configuration file can be found. Can be left blank. |
| authPlugin.typeName | string | `""` | Specifies the MapLarge authPlugin to use |
| config | object | `{}` | Allows for custom configurations for the MapLarge config.json, set as an object of key value pairs. @schema additionalProperties: true type: object required: false @schema |
| environmentVariables | list | `[{"name":"ML_STDERR_LOG_LEVEL","value":"2"},{"name":"ml_cfg_homepageRedirect","value":"dashboard"}]` | A map of extra environment variables to be added to the MapLarge container |
| existingRootPasswordSecretName | string | `""` | An existing secret that contains a value that will be used as the root password; the key must be set to `rootPassword` @schema required: false @schema |
| jsjs | object | `{"value":""}` | Allows for custom configurations for the js.js. This value is read in as-is, so each js.js option needs to be on it's own line. |
| rootPassword | string | `""` | If set, the root password will be set according to this value, otherwise a default value is created @schema required: false @schema |
| rootPasswordSecretName | string | `""` | If set, defines the name of the secret for the root password @schema required: false @schema |

### General

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| clusterConfig | object | `{}` | Extra configuration options for cluster.json set as an object of key value pairs @schema additionalProperties: true required: false @schema |
| extraLabels | map | `{}` | extraLabels Extra labels to apply to all resources |
| extraVolumeMounts | list | `[]` | extraVolumeMounts Specify any extra list of additional volumeMounts for MapLarge |
| extraVolumes | list | `[]` | extraVolumes Specify any extra list of additional volumes for MapLarge |
| nodeAffinityPreferences | list | `[]` | Sets the node affinity preferences for the MapLarge pod @schema additionalProperties: true required: false @schema |
| nodeAffinityRequirements | list | `[]` | Sets the nodeAffinityRequirements for the pod @schema additionalProperties: true required: false @schema |
| nodeSelector | object | `{}` | Sets the node selector for the MapLarge pod @schema additionalProperties: true required: false @schema |
| podAnnotations | object | `{}` | podAnnotations Extra annotations to add to your pods' metadata. Usually unnecessary. |
| podSecurityContext | object | `{}` | Sets the podSecurityContext @schema additionalProperties: true @schema |
| preferNodeAntiAffinity | bool | `false` | Set to true if you want to prefer that your replicas are placed on distinct nodes. |
| replicas | int | `3` | replicas The number of replicas to create in the StatefulSet. Defaults to 1. Has no effect if horizontal pod autoscaling is enabled. @schema required: true @schema |
| requireNodeAntiAffinity | bool | `true` | Set to true if you want to REQUIRE that your replicas are placed on different nodes. |
| securityContext | object | `{}` | Sets the securityContext @schema additionalProperties: true @schema |
| service.targetPort | int | `80` | If the MapLarge container is configured to serve requests on a port other than 80, define it here @schema required: true @schema |
| serviceAccount.create | bool | `false` | Specificies whether a service account should be created. If the deploying user does not have permissions to create an SA, then this value should be set to false. |
| serviceAccount.name | string | `""` | To use an existing service account, provide the name here. If not set and create is true, a name is generated using the maplarge.name template. |
| simpleNodeAffinityPreferences | list | `[]` | Sets simple node affinity preferences for the MapLarge pod @schema additionalProperties: true required: false @schema |
| simpleNodeAffinityRequirements | list | `[]` | Sets the simpleNodeAffinityRequirements for the pod @schema additionalProperties: true required: false @schema |
| simpleTolerations | list | `[]` | Sets a simple toleration for the MapLarge pod @schema additionalProperties: true required: false @schema |
| tolerations | object | `{}` | Sets the tolerations for the MapLarge pod @schema additionalProperties: true required: false @schema |

### Docker configurations

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| dockerCredentials | object | `{}` | this will create your pull secret for you. Required fields are registry, username, password, and email @schema additionalProperties: true @schema |

### Ingress Configuration

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| hostnameOverride | string | `""` | Rarely there is a time when you need to set the MapLarge hostname to something other than the ingress hostname, but if you do have that scenario, you can provide a hostname here to override the value that will be derived from the ingress.hosts[0].basehostname. Note, this does not modify the ingress hostname value. |
| ingress.annotations | object | `{}` | Annotations to set on the ingress object @schema additionalProperties: true @schema |
| ingress.class | string | `""` | Ingress class to use |
| ingress.enabled | bool | `true` | Enable ingress object |
| ingress.hosts[0] | object | `{"baseHostname":"example.maplarge.com","prefixes":0,"tls":{"enabled":false,"secretName":""}}` | Custom DNS name where MapLarge can be reached |
| ingress.hosts[0].prefixes | int | `0` | The number of dns prefixes to create |
| ingress.hosts[0].tls.enabled | bool | `false` | Controls if the site is TLS protected @schema required: false @schema |
| ingress.hosts[0].tls.secretName | string | `""` | The TLS secret to use if TLS protected @schema required: false @schema |

### Image Information

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| image.extraPullSecrets | list | `[]` | An array of any extra image pull secrets to add to the pod definition, in |
| image.pullPolicy | string | `"IfNotPresent"` | Image pull policy @schema enum: [Always,Never,IfNotPresent] @schema |
| image.pullSecretName | string | `""` | Secret to create or use to pull the docker image from the registry |
| image.repository | string | `""` | The fully qualified repository where the MapLarge image should be pulled from @schema type: string required: true example: docker.io/maplarge/maplarge @schema |
| image.tag | string | `""` | The MapLarge image tag to pull @schema type: string required: true example: latest @schema |

### License

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| license.existingSecretName | string | `""` | A secret name for an existing license secret. If creating your own license secret, the key must be "_maplarge_license.lic" @schema required: false @schema |
| license.license | string | `""` | The content of the MapLarge license if one has been provided to you @schema required: false @schema |

### Probe Configurations

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| livenessProbe.failureThreshold | int | `6` | Failure threshold for livenessProbe |
| livenessProbe.httpGet.path | string | `"/Cluster/IsAlive"` | Endpoint for the livenessProbe |
| livenessProbe.httpGet.port | string | `"http"` | Port for the livenessProbe |
| livenessProbe.httpGet.scheme | string | `"HTTP"` | Scheme for the livenessProbe |
| livenessProbe.initialDelaySeconds | int | `0` | Initial delay seconds for livenessProbe |
| livenessProbe.periodSeconds | int | `5` | Period seconds for livenessProbe |
| livenessProbe.successThreshold | int | `1` | Success Threshold for livenessProbe |
| livenessProbe.timeoutSeconds | int | `2` | Timeout seconds for livenessProbe |
| readinessProbe.failureThreshold | int | `3` | Failure threshold for readinessProbe |
| readinessProbe.httpGet.path | string | `"/Cluster/IsReadyForUser"` | Endpoint for the readinessProbe |
| readinessProbe.httpGet.port | string | `"http"` | Port for the readinessProbe |
| readinessProbe.httpGet.scheme | string | `"HTTP"` | Scheme for the readinessProbe |
| readinessProbe.initialDelaySeconds | int | `0` | Initial delay seconds for readinessProbe |
| readinessProbe.periodSeconds | int | `5` | Period seconds for readinessProbe |
| readinessProbe.successThreshold | int | `2` | Success Threshold for readinessProbe |
| readinessProbe.timeoutSeconds | int | `2` | Timeout seconds for readinessProbe |
| startupProbe.failureThreshold | int | `360` | Failure threshold for startupProbe |
| startupProbe.httpGet | object | `{"path":"/Cluster/IsReady","port":"http","scheme":"HTTP"}` | Endpoint for the startup probe |
| startupProbe.httpGet.port | string | `"http"` | Port for the startup probe |
| startupProbe.httpGet.scheme | string | `"HTTP"` | Scheme for the startup probe |
| startupProbe.periodSeconds | int | `10` | Period seconds for startupProbe |

### Notebook configurations

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| notebooks.enabled | bool | `false` | Enables MapLarge Notebooks and creates the necessary Service Account, Role and RoleBinding |

### Deployment Resources

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| resources | object | `{}` | Resources definition for the pod. @schema additionalProperties: true required: false @schema |

### Other Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| authPlugin.config | object | `{}` | Specific configuration values for the selected auth plugin. Must be declared as YAML, as the chart will convert to JSON. @schema additionalProperties: true type: object @schema |

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
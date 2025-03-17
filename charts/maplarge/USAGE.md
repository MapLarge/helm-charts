# MapLarge Helm Chart

## Overview

The MapLarge Helm chart provides a means to quickly configure and deploy a single- or multi-node MapLarge Server instance with minimal configuration, while also allowing fast updates and detailed overrides where needed.

This document covers the basic requirements of how to use the MapLarge Helm chart to deploy and modify a MapLarge Server instance in a standard Kubernetes environment.

Additionally, the generated YAML output is provided and explained so that it is possible for a cluster administrator to
hand-craft and customize a deployment for each individual component.

## Deploying MapLarge

There are only a few basic requirements to use the MapLarge helm chart to deploy MapLarge to your Kubernetes cluster

- Kuberenetes tools (`kubectl`) installed, configured, and authenticated, with the current context pointing to your desired cluster
- `helm` installed and functioning on your workstation
- All required access and TLS secrets, namespaces, and support requirements set up in the cluster
- A `values.yaml` file containing the desired configuration
- Access to the docker image to be used in the deployment

For the rest of the document, the following will apply to the commands and the resulting deployment:

- The namespace for the deployments will be **webapp-deployments** inside our cluster
- All the access and TLS secrets have been set up
- The maplarge helm chart repository has been added to your local setup according to the README
- Our deployment is to be named **tileset-gen**
- The values file is called `maplarge-values.yaml`

### Installing and Updating

Once the setup is correct, the commands to install the MapLarge Server cluster is very straightforward.

The original installation command using the helm charts is

```bash
$ helm install -n webapp-deployments tileset-gen maplarge -f maplarge-values.yaml
```

If, at any point going forward, you need to make changes to the cluster, you can update by using the following `helm upgrade` command

```bash
$ helm upgrade -n webapp-deployments tileset-gen maplarge -f maplarge-values.yaml
```

### Configuration using `maplarge-values.yaml`

In this scenario, MapLarge Server is being deployed with the following requirements:

- The full image identifier (repository to tag) is *docker.io/maplarge/server-netcore-dev:mlserver-fedora_40-4.99.0.1041-20250220143102*
- The image pull secret is *dockerhub-access-secret* in the same namespace
- There should be 3 nodes with drive space for 300 GiB and 256 GiB of memory
- 3D maps are disabled
- The corporate Active Directory system is being used for authentication
- There is a direct-access password being set
- When users log in, the will be directed to the `/dashboard` page

When placed all together in a values.yaml file, the starting configuration looks like this:

```yaml
image:
  repository: docker.io/maplarge/server-netcore-dev
  tag: mlserver-fedora_40-4.99.0.1041-20250220143102
  pullSecretName: dockerhub-access-secret

appDataVolumeSizeInGB: 300
replicas: 1

rootPassword: direct_access_password

resources:
  limits:
    memory: 256Gi
  requests:
    memory: 256Gi

config:
  allowedMlAuthUsers:
    - direct_access_svc@ml.com
  corsAllowedOrigins:
    - "%"
  authPluginTypeName: MapLarge.Engine.Unified.Auth.LdapAuthPlugin
  authPluginParams: config=/opt/maplarge/config/ldapAuth.json

jsjs:
  value: |
    ml.config.disable3D = true;
authPlugin:
  enabled: true
  typeName: MapLarge.Engine.Unified.Auth.LdapAuthPlugin
  filename: ldapAuth.json
  config:
    DefaultGroups:
      - nobody/nobody
    DefaultDomain: webapp
    GroupFormatOptions: Dn
    DomainBindMaps:
      - BindInfo:
          Hostname: webapp.maplarge.com
          TcpPortNumber: 389
          Username: CN=WebApp,OU=Service Accounts,OU=Users,OU=webapps,DC=webapp,DC=maplarge,DC=net
          Password: webapp_login_5711
          BindSsl: NotSsl
          BasePath: OU=WebApps,DC=webapp,DC=maplarge,DC=net
        NetBiosNames:
          - webapp
        LdapDomains:
          - webapp
    GroupMembershipRequirements:
      Has Access:
        - - key: allowedAccess
            values:
              - CN=Webapp,OU=Grups,OU=webapps,DC=webapp,DC=maplarge,DC=net
              - CN=Server Administrators,OU=Groups,OU=webapps,DC=webapp,DC=maplarge,DC=net
              - CN=High Availability Team,OU=Groups,OU=webapps,DC=webapp,DC=maplarge,DC=net
              - CN=DevOps Team,OU=Groups,OU=webapps,DC=webapp,DC=maplarge,DC=net
              - CN=WebApp Admins,OU=Groups,OU=webapps,DC=webapp,DC=maplarge,DC=net
              - CN=Data Team,OU=Groups,OU=webapps,DC=webapp,DC=maplarge,DC=net
              - CN=WebApp QA Testers,OU=Groups,OU=webapps,DC=webapp,DC=maplarge,DC=net
            requirement: any
            caseSensitive: false
      SysAdmin/Root:
        - - key: memberOf
            values:
              - CN=Kubernetes Admins,OU=Groups,OU=webapps,DC=webapp,DC=maplarge,DC=net
              - CN=Server Administrators,OU=Groups,OU=webapps,DC=webapp,DC=maplarge,DC=net
            requirement: any
            caseSensitive: false
      test/Admins:
        - - key: memberOf
            values:
              - CN=DevOps Team,OU=Groups,OU=webapps,DC=webapp,DC=maplarge,DC=net
              - CN=WebApp Admins,OU=Groups,OU=webapps,DC=webapp,DC=maplarge,DC=net
              - CN=WebApp QA Testers,OU=Groups,OU=webapps,DC=webapp,DC=maplarge,DC=net
              - CN=QA Testers US Based,OU=Groups,OU=webapps,DC=webapp,DC=maplarge,DC=net
            requirement: any
            caseSensitive: false
      test1/Editors:
        - - key: memberOf
            values:
              - CN=WebApp Developers,OU=Groups,OU=webapps,DC=webapp,DC=maplarge,DC=net
            requirement: any
            caseSensitive: false
      GeoData/Admins:
        - - key: memberOf
            values:
              - CN=Data Team,OU=Groups,OU=webapps,DC=webapp,DC=maplarge,DC=net
            requirement: any
            caseSensitive: false
      GeoData/Viewers:
        - - key: memberOf
            values:
              - CN=WebApp QA Testers,OU=Groups,OU=webapps,DC=webapp,DC=maplarge,DC=net
              - CN=QA Testers US Based,OU=Groups,OU=webapps,DC=webapp,DC=maplarge,DC=net
            requirement: any
            caseSensitive: false

ingress:
  enabled: true

requireNodeAntiAffinity: false

environmentVariables:
  - name: ML_STDERR_LOG_LEVEL
    value: "2"
  - name: ml_cfg_homepageRedirect
    value: "dashboard"

```

Once applied with the `helm install` or `helm upgrade` commands, the values are converted into a full deployment configuration and sent to the targeted Kubernetes cluster.

For more details on the available settings, refer to the **README.md** document in the chart repository.

### Resulting YAML sections

This sections goes over the output of the values.yaml, showing how the individual settings and defaults are applied.

For readability, the YAML sections have been broken up into their respective parts as separate files, rather than one massive output as it normally would be created.

#### ConfigMap

The first section to go over is the resulting ConfigMap.yaml.  The MapLarge Helm chart generates a YAML output that converts the necessary parts of the input config into the supporting configuration files used for server settings, authentication (if configured), web client settings, and cluster setup and communications.


```yaml
# Source: maplarge/templates/configmap.yaml
apiVersion: v1
data:
  cluster.json: "{\"AutoJoinCoreClusterMembers\":[\"http://tileset-gen-maplarge-0.tileset-gen-maplarge.webapp-deployments:80\"],\"DefaultClusterName\":\"maplarge-cluster\",\"DefaultSelfAddress\":\"http://${HOSTNAME}.tileset-gen-maplarge.webapp-deployments:80\"}"
  config.json: "\"{\\n  \\\"allowedMlAuthUsers\\\": [\\\"direct_access_svc@ml.com\\\"]\\n  \\\"corsAllowedOrigins\\\": [\\\"%\\\"],\\n  \\\"authPluginTypeName\\\": \\\"MapLarge.Engine.Unified.Auth.LdapAuthPlugin\\\",\\n  \\\"authPluginParams\\\": \\\"config=/opt/maplarge/config/ldapAuth.json\\\"\\n}\\n\""
  ldapAuth.json: "\"{\\n  \\\"DefaultGroups\\\": [\\\"nobody/nobody\\\"],\\n  \\\"DefaultDomain\\\": \\\"webapp\\\",\\n 
   
  ...[snip]...

  \\\"caseSensitive\\\": false\\n        }\\n      ]\\n    ]\\n}\\n\""
  js.js: "ml.config.disable3D = true;\n"
kind: ConfigMap
metadata:
  name: tileset-gen-maplarge-config
  labels:
    helm.sh/chart: maplarge
    app.kubernetes.io/instance: tileset-gen
    app.kubernetes.io/version: mlserver-fedora_40-4.99.0.1041-20250220143102
    app.kubernetes.io/managed-by: Helm
```

Noteworthy `values.yaml` settings:

| Setting        | Description/Effect                                                                                                                                                                                                                                                                             |
|:---------------|:-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| **config**     | This setting creates the ConfigMap entry `config.json`, and mounted at `/opt/maplarge/config/config.json'.  This contains settings not set in environment variables.  Values here are read-only and applied on every startup.                                                                  |
| **jsjs**       | This setting creates the ConfigMap entry `js.js`, and mounted at `/opt/maplarge/config/js.js`  This file is applied to the client-side javascript environment, and can control such things as tile and query request behavior, enabling or disabling map features, and XHR domain operations.  |
| **authPlugin** | When used and enabled, this creates the ConfigMap entry for the auth plugin configuration, located at `/opt/maplarge/config/[authconfig].json`.  This file contains settings and references for authentication and authorization using an external system, such as OAuth, LDAP, Kerberos, etc. |

#### Generated Secrets

The root user password is converted into a secret, which can be used for other services.

```yaml
# Source: maplarge/templates/rootpasswordsecret.yaml
apiVersion: v1
kind: Secret
metadata:
  name: tileset-gen-maplarge-root-password-secret
  labels:
    helm.sh/chart: maplarge
    app.kubernetes.io/instance: tileset-gen
    app.kubernetes.io/version: mlserver-fedora_40-4.99.0.1041-20250220143102
    app.kubernetes.io/managed-by: Helm
type: Opaque
data:
  rootPassword: ZGlyZWN0X2FjY2Vzc19wYXNzd29yZA==
```

Noteworthy `values.yaml` settings:

| Setting          | Description/Effect                                                                                                                                                                             |
|:-----------------|:-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| **rootPassword** | This value is set in the `values.yaml` and used in the **ML_ROOT_PASS** environment variable to set the password for the root account.  If not set, a random value will be generated and used. |

#### Docker Repo Credentials

If the docker access secret is not designated in the `values.yaml` file that is used, a generic secret of type `kubernetes.io/dockerconfigjson` is created and used in the rest of the generated yaml output.

Edit this secret to set the credentials used to pull the container image.


```yaml
# Source: maplarge/templates/pullsecret.yaml
apiVersion: v1
kind: Secret
metadata:
  name: dockerhub-access-secret
  labels:
    application: "tileset-gen"
    helm.sh/chart: maplarge
    app.kubernetes.io/instance: tileset-gen
    app.kubernetes.io/version: mlserver-fedora_40-4.99.0.1041-20250220143102
    app.kubernetes.io/managed-by: Helm
type: kubernetes.io/dockerconfigjson
data:
  .dockerconfigjson: eyJhdXRocyI6eyJkb2NrZXIuaW8iOnsidXNlcm5hbWUiOiJkb2NrZXJodWJ1c2VybmFtZSIsInBhc3N3b3JkIjoiZG9ja2VyaHVicGFzc3dvcmQiLCJlbWFpbCI6ImRvY2tlcmh1YkBlbWFpbGFkZHJlc3MuY29tIiwiYXV0aCI6IlpHOWphMlZ5YUhWaWRYTmxjbTVoYldVNlpHOWphMlZ5YUhWaWNHRnpjM2R2Y21RPSJ9fX0=
```
#### Networking

The next set of output pertain to routing traffic to and from the cluster.  DNS, load balancer, and ingress are all set up according standard installation practice.  All of these can be modified as necessary, and other deployment configurations are possible.

```yaml
# Source: maplarge/templates/headlessservice.yaml
apiVersion: v1
kind: Service
metadata:
  name: tileset-gen-maplarge
  labels:
    app.kubernetes.io/name: dns-headless-service
    app.kubernetes.io/component: cluster-dns
    app.kubernetes.io/part-of: maplarge
    application: "tileset-gen"
    helm.sh/chart: maplarge
    app.kubernetes.io/instance: tileset-gen
    app.kubernetes.io/version: mlserver-fedora_40-4.99.0.1041-20250220143102
    app.kubernetes.io/managed-by: Helm
spec:
  type: "ClusterIP"
  clusterIP: None
  sessionAffinity: None
  publishNotReadyAddresses: true
  ports:
    - port: 80
      targetPort: 80
      protocol: TCP
      name: web
  selector:
    app.kubernetes.io/instance: tileset-gen
```


```yaml
# Source: maplarge/templates/loadbalancerservice.yaml
apiVersion: v1
kind: Service
metadata:
  name: tileset-gen-maplarge-balancer
  labels:
    app.kubernetes.io/name: kubernetes-lb
    app.kubernetes.io/component: load-balancer
    app.kubernetes.io/part-of: maplarge
    application: "tileset-gen"
    helm.sh/chart: maplarge
    app.kubernetes.io/instance: tileset-gen
    app.kubernetes.io/version: CORD-34108-srvr-fedora_40-4.99.0.1041-20250220143102-ftr
    app.kubernetes.io/managed-by: Helm
spec:
  type: "ClusterIP"
  sessionAffinity: None
  ports:
    - port: 80
      targetPort: 80
      protocol: TCP
  selector:
    app.kubernetes.io/instance: tileset-gen
```

MapLarge uses "domain sharding" by default to reduce bottlenecks on tile requests.  Because of this, the ingress (and any external DNS entries) needs to cover traffic for the subdomains `[0-7]example.com`

```yaml
# Source: maplarge/templates/ingress.yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: tileset-gen-maplarge-ingress
  labels:
    application: "tileset-gen"
    helm.sh/chart: maplarge
    app.kubernetes.io/instance: tileset-gen
    app.kubernetes.io/version: mlserver-fedora_40-4.99.0.1041-20250220143102
    app.kubernetes.io/managed-by: Helm
  annotations:
    nginx.ingress.kubernetes.io/proxy-body-size: 2000m
    nginx.ingress.kubernetes.io/proxy-connect-timeout: "30"
    nginx.ingress.kubernetes.io/proxy-read-timeout: "600"
    nginx.ingress.kubernetes.io/proxy-send-timeout: "600"
    nginx.ingress.kubernetes.io/configuration-snippet: |
      more_set_headers "default-src 'self' 'unsafe-inline' wss: connect-src: 'unsafe-eval' https://webapp.maplarge.net https://0webapp.maplarge.net https://1webapp.maplarge.net https://2webapp.maplarge.net https://3webapp.maplarge.net https://4webapp.maplarge.net https://5webapp.maplarge.net https://6webapp.maplarge.net https://7webapp.maplarge.net; script-src 'self' 'unsafe-inline' 'unsafe-eval' wss: https://webapp.maplarge.net https://0webapp.maplarge.net https://1webapp.maplarge.net https://2webapp.maplarge.net https://3webapp.maplarge.net https://4webapp.maplarge.net https://5webapp.maplarge.net https://6webapp.maplarge.net https://7webapp.maplarge.net; frame-src 'self' https://webapp.maplarge.net https://0webapp.maplarge.net https://1webapp.maplarge.net https://2webapp.maplarge.net https://3webapp.maplarge.net https://4webapp.maplarge.net https://5webapp.maplarge.net https://6webapp.maplarge.net https://7webapp.maplarge.net; frame-ancestors 'self' https://webapp.maplarge.net https://0webapp.maplarge.net https://1webapp.maplarge.net https://2webapp.maplarge.net https://3webapp.maplarge.net https://4webapp.maplarge.net https://5webapp.maplarge.net https://6webapp.maplarge.net https://7webapp.maplarge.net; style-src * 'unsafe-inline'; img-src * data: 'unsafe-inline'; font-src * connect-src: 'self' wss: blob: data:; media-src *;";
spec:
  ingressClassName: nginx-internal
  tls:
    - hosts:
        - "webapp.maplarge.net"
        - "0webapp.maplarge.net"
        - "1webapp.maplarge.net"
        - "2webapp.maplarge.net"
        - "3webapp.maplarge.net"
        - "4webapp.maplarge.net"
        - "5webapp.maplarge.net"
        - "6webapp.maplarge.net"
        - "7webapp.maplarge.net"
      secretName: wildcard-dev-maplarge-net-tls-secret
  rules:
    - host: "webapp.maplarge.net"
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: tileset-gen-maplarge-balancer
                port:
                  number: 80
    - host: 0webapp.maplarge.net
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: tileset-gen-maplarge-balancer
                port:
                  number: 80
    - host: 1webapp.maplarge.net
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: tileset-gen-maplarge-balancer
                port:
                  number: 80
    - host: 2webapp.maplarge.net
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: tileset-gen-maplarge-balancer
                port:
                  number: 80
    - host: 3webapp.maplarge.net
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: tileset-gen-maplarge-balancer
                port:
                  number: 80
    - host: 4webapp.maplarge.net
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: tileset-gen-maplarge-balancer
                port:
                  number: 80
    - host: 5webapp.maplarge.net
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: tileset-gen-maplarge-balancer
                port:
                  number: 80
    - host: 6webapp.maplarge.net
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: tileset-gen-maplarge-balancer
                port:
                  number: 80
    - host: 7webapp.maplarge.net
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: tileset-gen-maplarge-balancer
                port:
                  number: 80

```

Noteworthy `values.yaml` settings:

| Setting                  | Description/Effect                                                                                                                                                                                                              |
|:-------------------------|:--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| **ingress.enabled**      | This tells the helm chart to generate the ingress according to the settings.  For purely internal deployments or MapLarge Server instances that are going to have traffic routed by different means, this can be set to `false` |
| **ingress.baseHostname** | This setting is used in a variety of ways, and should match the external DNS name: (1) For domain sharding subdomains. (2) For CORS security headers. (3) For routing basic traffic.                                            |

#### The StatefulSet (STS)

Finally, the StatefulSet used to control the actual pods and containers is generated.

```yaml
# Source: maplarge/templates/statefulset.yaml
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: tileset-gen-maplarge
  labels:
    app.kubernetes.io/name: "tileset-gen"
    application: "tileset-gen"
    app.kubernetes.io/component: maplarge-api-server
    app.kubernetes.io/part-of: maplarge
    helm.sh/chart: maplarge
    app.kubernetes.io/instance: tileset-gen
    app.kubernetes.io/version: mlserver-fedora_40-4.99.0.1041-20250220143102
    app.kubernetes.io/managed-by: Helm
spec:
  replicas: 3
  podManagementPolicy: "Parallel"
  revisionHistoryLimit: 10
  serviceName: tileset-gen-maplarge
  selector:
    matchLabels:
      app.kubernetes.io/instance: tileset-gen
  template:
    metadata:
      annotations:
        checksum/config: 263ff4d50e4d807903e3c89f516ef28012d297cd7e430c2fa05c78b88d1e37d
      labels:
        helm.sh/chart: maplarge
        app.kubernetes.io/instance: tileset-gen
        app.kubernetes.io/version: mlserver-fedora_40-4.99.0.1041-20250220143102
        app.kubernetes.io/managed-by: Helm
        application: "tileset-gen"
        app.kubernetes.io/name: "tileset-gen"
        app.kubernetes.io/component: maplarge-api-server
        app.kubernetes.io/part-of: maplarge
    spec:
      serviceAccountName: default
      imagePullSecrets:
        - name: "dockerhub-access-secret"
      containers:
        - name: maplarge
          env:
            - name: ML_ROOT_PASS
              valueFrom:
                secretKeyRef:
                  name: tileset-gen-maplarge-root-password-secret
                  key: rootPassword
            - name: ML_REPL_ENABLED
              value: "false"
            - name: ML_CLIENT_CONFIG_ENABLE_CORS
              value: "true"
            - name: ML_CORS_ALLOWED_ORIGINS
              value: '%'
            - name: ML_CONFIG_DIR
              value: /opt/maplarge/config
            - name: ML_CLIENT_CONFIG_JS_JS_PATH
              value: /opt/maplarge/config/js.js
            - name: ML_CLIENT_CONFIG_SERVER_HOSTNAME
              value: webapp.maplarge.net
            - name: ML_CLIENT_CONFIG_PREFIX_COUNT
              value: "8"
            - name: ML_USE_TRANSACTIONAL_DATABASE
              value: "true"
            - name: ML_STDERR_LOG_LEVEL
              value: "2"
            - name: ml_cfg_homepageRedirect
              value: dashboard
          image: "docker.io/maplarge/server-netcore-dev:mlserver-fedora_40-4.99.0.1041-20250220143102"
          imagePullPolicy: IfNotPresent
          ports:
            - containerPort: 80
              protocol: TCP
              name: http
          startupProbe:
            failureThreshold: 360
            httpGet:
              path: /Cluster/IsReady
              port: http
              scheme: HTTP
            periodSeconds: 10
          livenessProbe:
            failureThreshold: 6
            httpGet:
              path: /Cluster/IsAlive
              port: http
              scheme: HTTP
            initialDelaySeconds: 0
            periodSeconds: 5
            successThreshold: 1
            timeoutSeconds: 2
          readinessProbe:
            failureThreshold: 3
            httpGet:
              path: /Cluster/IsReadyForUser
              port: http
              scheme: HTTP
            initialDelaySeconds: 0
            periodSeconds: 5
            successThreshold: 2
            timeoutSeconds: 2
          resources:
            limits:
              cpu: 4
              memory: 256Gi
            requests:
              cpu: 1
              memory: 256Gi
          terminationMessagePath: "/dev/termination-log"
          terminationMessagePolicy: "File"
          volumeMounts:
            - mountPath: /opt/maplarge/App_Data
              name: maplarge-data
            - mountPath: /opt/maplarge/config/cluster.json
              name: config
              subPath: cluster.json
            - mountPath: /opt/maplarge/config/config.json
              name: config
              subPath: config.json
      dnsPolicy: ClusterFirst
      restartPolicy: Always
      schedulerName: default-scheduler
      terminationGracePeriodSeconds: 120
      volumes:
        - name: config
          configMap:
            name: "tileset-gen-maplarge-config"
  updateStrategy:
    type: "RollingUpdate"
  volumeClaimTemplates:
    - metadata:
        name: maplarge-data
      spec:
        accessModes:
          - ReadWriteOnce
        resources:
          requests:
            storage: 300Gi
        storageClassName: openebs-hostpath
        volumeMode: Filesystem
```

Noteworthy `values.yaml` settings:

| Setting                   | Description/Effect                                                                                                                                                                                                                                                                |
|:--------------------------|:----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| **rootPassword**          | This setting is used in the generated secret, and that secret is used to set the environment variable **ML_ROOT_PASS**                                                                                                                                                            |
| **appDataVolumeSizeInGB** | This setting determines the PVC size that will be mounted on the path `/opt/maplarge/App_Data`.  Choosing the correct size is largely determined by the planned usage and expected data volume.  The resulting PVC will have the name `maplarge-data-[helm-install-name]-[pod#]`. |
| **replicas**              | This value sets the number of pods that will be spun up. In general, each pod will have the name `[helm-install-name]-maplarge-[pod #]`                                                                                                                                           |
| **image.tag**             | This is the image tag that will be used to stand up the pods, and is a minimally required value to apply the MapLarge Helm chart.                                                                                                                                                 |

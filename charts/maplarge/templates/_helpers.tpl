{{/* vim: set filetype=mustache: */}}

{{/*
This is the "name" of the Chart that is used by other templates in this chart to form a qualified name for the application. By default, this is the name of the Chart; can be overriden via `.Values.nameOverride`
*/}}

{{- define "maplarge.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" | trimSuffix "." }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}

{{- define "maplarge.fullname" -}}
  {{- if .Values.fullnameOverride }}
    {{- .Values.fullnameOverride | trunc 52 | trimSuffix "-" | trimSuffix "." | lower }}
  {{- else }}
    {{- $name := default .Chart.Name .Values.nameOverride }}
    {{- if contains $name .Release.Name }}
      {{- .Release.Name | trunc 52 | trimSuffix "-"  | trimSuffix "." | lower }}
    {{- else }}
      {{- printf "%s-%s" .Release.Name $name | trunc 52 | trimSuffix "-" | trimSuffix "." | lower }}
    {{- end }}
  {{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}

{{- define "maplarge.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" | trimSuffix "." }}
{{- end }}

{{/*
The tag for MapLarge API Server
*/}}

{{- define "maplarge.image" -}}
{{- default "4.5.0" .Values.image.tag | trunc 63 | trimSuffix "-" | trimSuffix "." }}
{{- end }}

{{/*
Labels that will be applied to every single object
*/}}
{{- define "maplarge.labels" -}}
helm.sh/chart: {{ include "maplarge.chart" . }}
{{ include "maplarge.selectorLabels" . }}
app.kubernetes.io/version: {{ include "maplarge.image" . }}
{{- if .Values.team }}
maplarge.com/project: {{ .Values.team | quote }}
team: {{ .Values.team | quote }}
app.kubernetes.io/owner: {{ .Values.team | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- range $key, $value := .Values.extraLabels }}
{{ $key }}: {{ $value | quote }}
{{- end }}
{{- end }}

{{/*
Selector labels to point the load balancer service at the appropriate pods

DEV-56 https://maplarge.atlassian.net/browse/DEV-56
Removed app name from selector labels because now the app name is not going to be the same for all things in the Helm chart.

*/}}

{{- define "maplarge.selectorLabels" -}}
  app.kubernetes.io/instance: {{ .Release.Name | trimSuffix "-" | trimSuffix "." }}
{{- end }}

{{/*
Create the name of the headless service to use. The headless service is used for DNS so that MapLarge nodes can communicate with each other.
*/}}

{{- define "maplarge.headlessServiceName" -}}
{{- $name := default (include "maplarge.fullname" .) .Values.headlessServiceName -}}
{{- printf "%s" $name | trunc 63 }}
{{- end }}

{{/*
Image pull secret name
*/}}

{{- define "maplarge.pullSecretName" }}
{{- if and (.Values.image) (.Values.image.pullSecretName) }}
{{- .Values.image.pullSecretName }}
{{- else if .Values.dockerCredentials }}
{{- include "maplarge.fullname" . -}}-pull-secret
{{- end}}
{{- end }}

{{/*
`ConfigMap` name
*/}}

{{- define "maplarge.configMapName" }}
{{- include "maplarge.fullname" . -}}-config
{{- end }}

{{/*
Load balancer service name
Naming and length defintions: https://kubernetes.io/docs/concepts/overview/working-with-objects/names/#dns-subdomain-names
Max length for a DNS subdomain name is 253
*/}}

{{- define "maplarge.balancerServiceName" }}
{{- $fullnameLen := len (include "maplarge.fullname" .) -}}
{{- $balencerLen := len "-balancer" -}}
{{- $totalLen := add $fullnameLen $balencerLen -}}
{{- $name := "" -}}
{{- if gt $totalLen 253 -}}
  {{- $toTrunc := sub $fullnameLen $balencerLen | int -}}
  {{- $name = include "maplarge.fullname" . | trunc $toTrunc | trimSuffix "-" | trimSuffix "." -}}
{{- else -}}
  {{- $name = include "maplarge.fullname" . -}}
{{- end -}}
{{- printf "%s-%s" $name "balancer" }}
{{- end }}

{{/*
Cellular (LTE) load balancer service name
*/}}

{{- define "maplarge.lteServiceName" }}
{{- $fullnameLen := len (include "maplarge.fullname" .) -}}
{{- $balencerLen := len "-lte-balancer" -}}
{{- $toTrunc := sub $fullnameLen $balencerLen | int -}}
{{- $name := include "maplarge.fullname" . | trunc $toTrunc -}}
{{- printf "%s-%s" $name "lte-balancer" }}
{{- end }}

{{/*
Ingress name
*/}}

{{- define "maplarge.ingressName" }}
{{- include "maplarge.fullname" . -}}-ingress
{{- end }}

{{/*
Root password secret name
*/}}

{{- define "maplarge.rootPasswordSecretName" }}
  {{- if .Values.existingRootPasswordSecretName }}
    {{- .Values.existingRootPasswordSecretName }}
  {{- else if .Values.rootPasswordSecretName }}
    {{- .Values.rootPasswordSecretName }}
  {{- else }}
    {{- include "maplarge.fullname" . -}}-root-password-secret
  {{- end }}
{{- end }}

{{/*
Contents of `cluster.json` file, typically located either in `/opt/maplarge/App_Data/config/cluster.json` or `/opt/maplarge/config/cluster.json`. Important because it is used to automatically join nodes to the cluster. Currently set to autojoin every node and make every node a voting member. This behavior may be changed in the near future so that only the first few nodes are set to be voting members.
*/}}

{{- define "maplarge.clusterConfigJson" }}
  {{- $namespace := .Release.Namespace }}
  {{- $statefulSetName := include "maplarge.fullname" . }}
  {{- $headlessServiceName := include "maplarge.headlessServiceName" . }}
  {{- $clusterConfigToMerge := .Values.clusterConfig }}
  {{- $port := default 80 .Values.service.targetPort }}
  {{- $defaultSelfAddress := printf "http://${HOSTNAME}.%s.%s:%d" $headlessServiceName .Release.Namespace (int $port) }}
  {{- $defaultClusterName := default "maplarge-cluster" .Values.defaultClusterName }}
  {{- $autoJoinMembers := list }}
  {{- $upperIndex := default .Values.replicas .Values.numberOfAutoJoinMembers }}
  {{- range untilStep 0 (int $upperIndex) 1 }}
    {{- $autoJoinMembers = append $autoJoinMembers (printf "http://%s-%d.%s.%s:%d" $statefulSetName (int .) $headlessServiceName $namespace (int $port)) }}
  {{- end }}
  {{- $clusterConfig := (dict "DefaultSelfAddress" $defaultSelfAddress "DefaultClusterName" $defaultClusterName "AutoJoinCoreClusterMembers" $autoJoinMembers ) }}
  {{- $mergedClusterConfig := merge $clusterConfigToMerge $clusterConfig }}
  {{- $clusterConfigJson := toJson $mergedClusterConfig }}
  {{- $clusterConfigJson }}
{{- end }}

{{/*
Returns the proper service account name depending if an explicit service account name is set
in the values file. If the name is not set it will default to either common.names.fullname if webhook.serviceAccount.create
is true or default otherwise.
*/}}
{{- define "maplarge.serviceAccountName" -}}
    {{- if or .Values.serviceAccount.create .Values.notebooks.enabled -}}
        {{- if (empty .Values.serviceAccount.name) -}}
          {{- include "maplarge.name" . -}}
        {{- else -}}
          {{ default "default" .Values.serviceAccount.name }}
        {{- end -}}
    {{- else -}}
        {{ default "default" .Values.serviceAccount.name }}
    {{- end -}}
{{- end -}}

{{/*
Builds the js.js based on the inputs from the values if Notebooks are enabled.
*/}}
{{- define "maplarge.jsjs" }}
  {{- $jsjs := "" -}}
  {{- $nJsjs := "" -}}
  {{- if .Values.jsjs.value -}}
  {{- $jsjs = cat .Values.jsjs.value "\n" }}
  {{- end }}
  {{- if .Values.notebooks.enabled }}
  {{- $nJsjs = "ml.config.enableNotebooks = true;"}}
  {{- end }}
  {{- printf "%s%s" $jsjs $nJsjs}}
{{- end }}

{{/*
If the deployment needs a different hostname than the one defined in the ingress object, allow the user to specify
it as a value and use it, otherwise, we can just use the hostname from the ingress.
*/}}
{{- define "maplarge.hostname" -}}
  {{- if .Values.hostnameOverride -}}
  {{- .Values.hostnameOverride -}}
  {{- else -}}
  {{- (index .Values.ingress.hosts 0).baseHostname }}
  {{- end -}}
{{- end -}}


{{/*
Checks to see if this chart has been deployed with v1.X of the MapLarge helm chart. v2.X changes the name
of the PVC, and in doing so, will lose the data from the original 1.X version. If a pvc with app-data-<name>
is found, then it will be used vs. being updated.
*/}}
{{- define "maplarge.pvcName" -}}
{{ $search_for := printf "%s-%s" "app-data" $.Release.Name }}
{{ $pvc_name := "maplarge-data" }}
{{ $found := false }}

{{- range $index, $pvcs := (lookup "v1" "PersistentVolumeClaim" $.Release.Namespace "").items }}
  {{- $pvc := $pvcs.metadata.name }}
  {{- if and (not $found) (contains $search_for $pvc) -}}
    {{ $pvc_name = "app-data" }}
    {{ $found = true }}
  {{- end }}
{{- end }}

{{- printf "name: %s" $pvc_name }}
{{- end }}

{{/*
Generate Content Security Policy for web deployments

@param .hostName    base host name for the deployment
@param .csp         A map representing the csp passed in
                         from the values.yaml
*/}}
{{- define "maplarge.contentSecurityPolicy" -}}
{{ $hostList := "" }}
{{- if .hostName }}
{{ $hostList = printf "https://%s" .hostName }}
{{- range untilStep 0 8 1 }}
{{- $hostList = printf "%s https://%d%s" $hostList . $.hostName }}
{{- end }}
{{- end }}
{{- $defaultsrc := "" }}
{{- $scriptsrc := "" }}
{{- $stylesrc := "" }}
{{- $imgsrc := "" }}
{{- $framesrc := "" }}
{{- $frameancestors := "" }}
{{- $fontsrc := "" }}
{{- $mediasrc := "" }}
{{- $cspObj := .csp }}
{{- if not $cspObj }}
{{- $cspObj = "" }}
{{- end }}
{{- if $cspObj.defaultSrc }}
{{- $defaultsrc = printf "default-src %s" $cspObj.defaultSrc }}
{{- else }}
{{- $defaultsrc = "default-src 'self' 'unsafe-inline' wss: connect-src: 'unsafe-eval'" }}
{{- end }}
{{- if $cspObj.scriptSrc }}
{{- $scriptsrc = printf "script-src %s" $cspObj.scriptSrc }}
{{- else }}
{{- $scriptsrc = "script-src 'self' 'unsafe-inline' 'unsafe-eval' wss:" }}
{{- end }}
{{- if $cspObj.styleSrc }}
{{- $stylesrc = printf "style-src %s" $cspObj.styleSrc }}
{{- else }}
{{- $stylesrc = "style-src * 'unsafe-inline'" }}
{{- end }}
{{- if $cspObj.imgSrc }}
{{- $imgsrc = printf "img-src %s" $cspObj.imgSrc }}
{{- else }}
{{- $imgsrc = "img-src * data: 'unsafe-inline'" }}
{{- end }}
{{- if $cspObj.frameSrc }}
{{- $framesrc = printf "frame-src %s" $cspObj.frameSrc }}
{{- else }}
{{- $framesrc = "frame-src 'self'" }}
{{- end }}
{{- if $cspObj.frameAncestors }}
{{- $frameancestors = printf "frame-ancestors %s" $cspObj.frameAncestors }}
{{- else }}
{{- $frameancestors = "frame-ancestors 'self'" }}
{{- end }}
{{- if $cspObj.fontSrc }}
{{- $fontsrc = printf "font-src %s" $cspObj.fontSrc }}
{{- else }}
{{- $fontsrc = "font-src * connect-src: 'self' wss: blob: data:" }}
{{- end }}
{{- if $cspObj.mediaSrc }}
{{- $mediasrc = printf "media-src %s" $cspObj.mediaSrc }}
{{- else }}
{{- $mediasrc = "media-src *" }}
{{- end }}
{{- printf "%s %s; %s %s; %s %s; %s %s; %s; %s; %s; %s;" $defaultsrc $hostList $scriptsrc $hostList $framesrc $hostList $frameancestors $hostList $stylesrc $imgsrc $fontsrc $mediasrc }}
{{- end }}

{{/*
    Dumps variables to console and stops processing.  Used for debugging
    usage:  {{- template "maplarge.var_dump" $yourVariable }}
*/}}
{{- define "maplarge.var_dump" -}}
{{- . | mustToPrettyJson | printf "\nThe JSON output of the dumped var is: \n%s" | fail }}
{{- end -}}

{{/*
  Defines a name for the license, unless an existing secret has been provided
*/}}
{{- define "maplarge.licenseName" }}
{{- if .Values.license.existingSecretName }}
{{- .Values.license.existingSecretName }}
{{- else }}
{{- include "maplarge.fullname" . -}}-license
{{- end }}
{{- end }}


{{/*
Defines a name for the license directory as used by the File Globs
*/}}
{{- define "maplarge.licenseDir" }}
{{- $path := printf "%s/*" "license" }}
{{- printf "%s" $path }}
{{- end }}

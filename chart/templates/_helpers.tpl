{{/*
Expand the name of the chart.
*/}}
{{- define "redis.name" -}}
{{- .Chart.Name }}
{{- end }}

{{- define "redis.version" -}}
{{ default .Chart.AppVersion .Values.redis }}
{{- end }}

{{- define "redis.image" -}}
{{ printf "redis:%s" (include "redis.version" .) }}
{{- end }}

{{- define "redis.auth" -}}
{{- default "" .Values.password }}
{{- end }}

{{- define "redis.tlsSecretName" -}}
{{- .Values.tlsSecretName }}
{{- end }}

{{- define "redis.mode" -}}
{{- .Values.mode }}
{{- end }}

{{- define "redis.size" -}}
{{- .Values.size }}
{{- end }}

{{- define "redis.repl" -}}
{{- .Values.repl }}
{{- end }}

{{- define "redis.exporter.enabled" -}}
{{- .Values.exporter.enabled }}
{{- end }}
{{- define "redis.exporter.image" -}}
{{- printf "%s:%s" .Values.exporter.image .Values.exporter.tag }}
{{- end }}

{{- define "redis.persistence.enabled" -}}
{{- .Values.persistence.enabled }}
{{- end }}
{{- define "redis.persistence.size" -}}
{{- .Values.persistence.size }}
{{- end }}
{{- define "redis.persistence.class" -}}
{{- .Values.persistence.class }}
{{- end }}

{{- define "redis.imagePullPolicy" -}}
{{- default "IfNotPresent" .Values.imagePullPolicy }}
{{- end }}

{{ define "redis.cm" }}redis-conf{{ end }}
{{ define "redis.sec" }}redis-auth{{ end }}

{{- define "redis.kind" -}}
{{- if eq "standalone" (include "redis.mode" .) }}
{{- printf "Redis" }}
{{- else }}
{{- printf "Redis%s" ( title (include "redis.mode" .)) }}
{{- end }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}

{{- define "redis.fullname" -}}
{{- .Release.Name }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "redis.chart" -}}
{{- printf "%s-operator-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "redis.labels" -}}
helm.sh/chart: {{ include "redis.chart" . }}
{{ include "redis.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "redis.selectorLabels" -}}
app.kubernetes.io/name: {{ include "redis.name" . }}-{{ include "redis.mode" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

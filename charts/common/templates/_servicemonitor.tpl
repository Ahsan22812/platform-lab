{{/*
common.servicemonitor — a standard ServiceMonitor.

Rendered only when the Prometheus Operator CRD exists in the cluster
(the .Capabilities check), so a chart that includes this still installs
cleanly before kube-prometheus-stack — the SM appears once kps is up and
the chart is re-applied. A chart that wants different scrape config
doesn't include this and writes its own.

Usage — the consuming chart's templates/servicemonitor.yaml is just:
  {{ include "common.servicemonitor" . }}

Portability: serviceMonitor.labels (optional, default unset) merges extra
labels into metadata — for clusters whose Prometheus label-gates discovery
(e.g. the kube-prometheus-stack default `release: <name>` selector). Our
lab's Prometheus discovers ALL ServiceMonitors (open selector), so leave
it unset here; set it per-deployment when a gated cluster requires it.
*/}}
{{- define "common.servicemonitor" -}}
{{- if .Capabilities.APIVersions.Has "monitoring.coreos.com/v1" -}}
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: {{ include "common.fullname" . }}
  labels:
    {{- include "common.labels" . | nindent 4 }}
    {{- with .Values.serviceMonitor.labels }}
    {{- toYaml . | nindent 4 }}
    {{- end }}
spec:
  selector:
    matchLabels:
      {{- include "common.selectorLabels" . | nindent 6 }}
  endpoints:
    - port: {{ .Values.serviceMonitor.port | default "http" }}
      path: {{ .Values.serviceMonitor.path | default "/metrics" }}
      interval: {{ .Values.serviceMonitor.interval | default "30s" }}
      scrapeTimeout: {{ .Values.serviceMonitor.scrapeTimeout | default "10s" }}
{{- end -}}
{{- end -}}

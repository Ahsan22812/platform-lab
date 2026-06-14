{{/*
common.topologySpreadConstraints — a pod-spec SNIPPET (not a standalone
object), injected into a Deployment's pod template.

Default whenUnsatisfiable: ScheduleAnyway (soft) — best-effort spread
that never leaves pods Pending. Quorum systems that need hard spread
set whenUnsatisfiable: DoNotSchedule in their values. labelSelector
comes from the shared selectorLabels, so it always matches the workload.

Usage — inside the Deployment's pod spec (template.spec level):
  {{- include "common.topologySpreadConstraints" . | nindent 6 }}
*/}}
{{- define "common.topologySpreadConstraints" -}}
topologySpreadConstraints:
  - maxSkew: {{ .Values.topologySpread.maxSkew }}
    topologyKey: {{ .Values.topologySpread.topologyKey }}
    whenUnsatisfiable: {{ .Values.topologySpread.whenUnsatisfiable }}
    labelSelector:
      matchLabels:
        {{- include "common.selectorLabels" . | nindent 8 }}
{{- end -}}

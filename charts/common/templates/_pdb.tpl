{{/*
common.pdb — a standard PodDisruptionBudget.

Rendered unconditionally (no replica gate): with maxUnavailable: 1 it's
a harmless no-op on single-replica workloads and real protection on
multi-replica ones. A chart that needs different disruption semantics
simply doesn't include this and writes its own.

Usage — the consuming chart's templates/pdb.yaml is just:
  {{ include "common.pdb" . }}
*/}}
{{- define "common.pdb" -}}
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: {{ include "common.fullname" . }}
  labels:
    {{- include "common.labels" . | nindent 4 }}
spec:
  maxUnavailable: {{ .Values.podDisruptionBudget.maxUnavailable }}
  selector:
    matchLabels:
      {{- include "common.selectorLabels" . | nindent 6 }}
{{- end -}}

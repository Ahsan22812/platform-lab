{{/*
podinfo-specific named templates.

Shared helpers — name, labels, selectorLabels, PDB, ServiceMonitor,
topologySpreadConstraints — come from the `common` library chart and are
included directly (e.g. {{ include "common.fullname" . }}). This file is
ONLY for helpers unique to podinfo, so we don't pollute the shared library
with one chart's specifics. Today that's just the image reference.
*/}}

{{/*
podinfo.image — the fully-pinned container image reference.

Built as repository:tag@digest. The image is digest-pinned by default
(the tag is mutable, the digest isn't; tag is kept for human readability
while the digest is what actually pins the pull). If digest is empty —
e.g. a local/dev override — fall back to repository:tag instead of
emitting a dangling "@", which would be an invalid reference.
*/}}
{{- define "podinfo.image" -}}
{{- $img := .Values.image -}}
{{- if $img.digest -}}
{{- printf "%s:%s@%s" $img.repository $img.tag $img.digest -}}
{{- else -}}
{{- printf "%s:%s" $img.repository $img.tag -}}
{{- end -}}
{{- end -}}

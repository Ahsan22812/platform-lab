{{/*
common.checksumAnnotation — the render-time config fingerprint.

Renders the CALLING chart's templates/configmap.yaml, hashes it, and
emits the hash as a pod-template annotation. Kubernetes only restarts
pods when the POD SPEC changes, and an in-place ConfigMap update never
changes it — this annotation converts "config changed" into "pod spec
changed", so a config change rolls the workload and anything else
leaves it alone. (Out-of-band changes — e.g. ESO-rotated secrets — are
invisible to a render-time hash; that's Reloader's territory, see
docs/roadmap.md Layer 5.)

Convention: the consumer keeps its config in templates/configmap.yaml.
Usage, inside the workload's POD TEMPLATE metadata (not the workload's
own metadata):

  template:
    metadata:
      annotations:
        {{ include "common.checksumAnnotation" . | nindent 8 }}

.Template.BasePath resolves to the CALLER's templates/ dir because the
caller passes its own root context.
*/}}
{{- define "common.checksumAnnotation" -}}
checksum/config: {{ include (printf "%s/configmap.yaml" .Template.BasePath) . | sha256sum }}
{{- end -}}

{{/*
common.checksumAnnotationFor — same trick for any template file.

For charts whose config isn't (only) templates/configmap.yaml: pass the
root context and the file name; the annotation key is derived from the
file name, so multiple calls don't collide. Usage:

  annotations:
    {{ include "common.checksumAnnotationFor" (list . "secret.yaml") | nindent 8 }}
    {{ include "common.checksumAnnotationFor" (list . "configmap-nginx.yaml") | nindent 8 }}

→ checksum/secret: <hash>
→ checksum/configmap-nginx: <hash>

Caution when hashing a SECRET template: the hash is world-readable on
the pod. sha256 isn't reversible, but someone who knows the template
and all values except a low-entropy secret could brute-force it
offline against candidate renders. Fine for random/high-entropy
secrets; for anything guessable, prefer an ESO-managed Secret (not
rendered from git at all → Reloader territory, Layer 5).
*/}}
{{- define "common.checksumAnnotationFor" -}}
{{- $root := index . 0 -}}
{{- $file := index . 1 -}}
checksum/{{ $file | base | trimSuffix ".yaml" }}: {{ include (printf "%s/%s" $root.Template.BasePath $file) $root | sha256sum }}
{{- end -}}

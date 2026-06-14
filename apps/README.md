# apps

**Application source code** for services we own — Go/whatever source plus
its `Dockerfile`. One directory per service:

```
apps/<service>/
  cmd/ , internal/ , ...   # source
  Dockerfile               # how to build the image
```

**No Helm charts here.** Deployment charts live in [`../charts/`](../charts/)
— keeping code and charts separate means a `docker build` of a service
sees only code (clean build context, no chart files to `.dockerignore`).

Third-party apps we only *deploy* (e.g. podinfo) have no entry here —
just a chart under `../charts/`.

_Empty for now — the lab's own services land here as later layers add
something worth building and deploying._

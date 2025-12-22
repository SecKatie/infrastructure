# Running ArchiveBox on Kubernetes with NFS Storage

If you're trying to run ArchiveBox on Kubernetes with NFS-backed persistent volumes, you may encounter CrashLoopBackOff issues. Here's what we learned and how to fix it.

## The Problem

The ArchiveBox Docker image has an entrypoint script (`/app/bin/docker_entrypoint.sh`) that:
1. Runs `usermod`/`groupmod` to set the archivebox user's UID/GID
2. Runs `chown` on `/data` to fix ownership
3. Drops privileges to the archivebox user
4. Runs the actual archivebox command

This works great on local Docker, but on Kubernetes with NFS:
- **Without securityContext**: The entrypoint runs as root and tries to `chown /data`, which NFS typically blocks (`Operation not permitted`)
- **With securityContext (runAsUser: 911)**: The container starts as non-root, so `usermod`/`groupmod`/`chown` all fail silently, and the entrypoint exits

## The Solution

Bypass the entrypoint entirely by using `command` in your deployment, and set the securityContext to run as the archivebox user (UID 911):

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: archivebox
spec:
  replicas: 1
  selector:
    matchLabels:
      app: archivebox
  template:
    metadata:
      labels:
        app: archivebox
    spec:
      securityContext:
        runAsUser: 911
        runAsGroup: 911
        fsGroup: 911
      containers:
        - name: archivebox
          image: archivebox/archivebox:latest
          command: ["archivebox"]  # Bypasses docker_entrypoint.sh
          args: ["server", "--quick-init", "0.0.0.0:8000"]
          ports:
            - containerPort: 8000
          volumeMounts:
            - name: data
              mountPath: /data
      volumes:
        - name: data
          persistentVolumeClaim:
            claimName: archivebox-data
```

## NFS Permissions

Make sure your NFS export allows UID 911 to read/write. You may need to:
- Set directory permissions to `777` or owned by UID 911
- Configure NFS user mapping appropriately (e.g., `anonuid=911,anongid=911` or map all users)

## Debugging Tips

If you're still having issues, test with a debug pod:

```bash
kubectl run -n archivebox debug --image=archivebox/archivebox:latest --rm -it \
  --restart=Never --overrides='{
    "spec": {
      "securityContext": {"runAsUser": 911, "runAsGroup": 911, "fsGroup": 911},
      "containers": [{
        "name": "debug",
        "image": "archivebox/archivebox:latest",
        "command": ["archivebox", "server", "--quick-init", "0.0.0.0:8000"],
        "volumeMounts": [{"name": "data", "mountPath": "/data"}]
      }],
      "volumes": [{"name": "data", "persistentVolumeClaim": {"claimName": "archivebox-data"}}]
    }
  }'
```

This helped us identify exactly where things were failing.

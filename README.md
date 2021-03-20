# ARK Survival Evolved helm charts

## How It Works
The chart is based on docker image https://github.com/thmhoag/arkserver 
which uses `arkmanager` (https://github.com/arkmanager/ark-server-tools) 
to install and update ARK from steam as well as mods.

It creates a deployment for each server defined in your `values.yaml`, with `replicaCount=0` by default.
All servers will share the server files and `clusters` directory.

### Requirements for Kubernetes
* ARK communicates its port to the client, thus the external port must be identical to the port where the ARK pod is listening.
* Required persistent volumes:
  * one volume for each server (mounted as `/ark`)
  * one volume for the shared cluster files (mounted as `/arkclusters`)
  * one volume for the shared server (game) files (the biggest volume) to save space (mounted as `/arkserver`)

### Installation
First start ONE server, he should also have all mods configured that you want to use

```shell script
helm repo add drpsychick https://drpsychick.github.io/ark-server-charts
helm repo update
helm search repo drpsychick
helm upgrade --create-namespace --install --values values.yaml arkcluster1 drpsychick/ark-cluster
```

Start the server with the following settings:
```yaml
servers:
  - name: extinction
    updateOnStart: true
    mods: [ "889745138", "731604991", ... ]
```

This will download and install ark server and modules.

### Clustering
Minimal definition of a server:
```yaml
servers:
  - name: extinction
    map: Extinction
```

If you only have 1 public IP address available, you **must** set ports for each server:
```yaml
servers:
  - name: extinction
    ports:
      queryudp: 27015
      gameudp: 7770
      rcon: 32330
```

### Shared Server Files
TODO: make this optional!

Server files are shared across multiple ARK instances of the cluster
```yaml
extraEnvVars:
  - name: am_arkStagingDir
    value:
  - name: ARKSERVER_SHARED
    value: /arkserver
``` 

### Limit resources
Optionally create a quota for your namespace, see https://kubernetes.io/docs/tasks/administer-cluster/manage-resources/

Example:
```yaml
apiVersion: v1
kind: ResourceQuota
metadata:
  name: arkcluster-quota
spec:
  hard:
    # keep requests low when running on-demand
    requests.cpu: "1"
    requests.memory: 8Gi
    # limit to max 3 running servers
    limits.cpu: "4"
    limits.memory: 20Gi
```

## Credits
Inspired by
* https://github.com/itzg/minecraft-server-charts
* https://github.com/thmhoag/arkserver
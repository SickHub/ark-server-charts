# ark-cluster : an ARK Survival Evolved cluster Helm Chart
ARK Survival Evolved is sandbox survival game available for example on Steam: https://store.steampowered.com/app/346110/ARK_Survival_Evolved/

## How It Works
The chart is based on the docker image https://github.com/thmhoag/arkserver 
which uses `arkmanager` (https://github.com/arkmanager/ark-server-tools) 
to install and update ARK from steam as well as mods.

It creates a deployment for each server defined in your `values.yaml`, with `replicas: 0` by default.
All servers will share the `ShooterGame` server files and `clusters` directory, once you have [persistence](#persistence) configured.

### Requirements for Kubernetes
* ARK communicates its port to the client, thus the external port must be identical to the port where the ARK pod is listening.
* Required persistent volumes:
  * one volume for the shared server (game) files (the biggest volume) to save space (mounted as `/arkserver`)
  * one volume for each server (mounted as `/arkserver/ShooterGame/Saved`)
  * one volume for the shared cluster files (mounted as `/arkserver/ShooterGame/Saved/clusters`)

## Deploy ark-cluster
First start ONE server, he should also have all mods configured that you want to use.

You **must** configure [`persistence`](#persistence), if you want your data to be persisted (Game, Saved, ... everything).

```shell script
helm repo add ark https://drpsychick.github.io/ark-server-charts
helm repo update
helm search repo ark
helm upgrade --create-namespace --namespace ark --install --values values.yaml arkcluster ark/ark-cluster
```

Start the **first** server with the following setting:
```yaml
servers:
  extinction:
    updateOnStart: true
```

This will download and install ark server and modules.

### Clustering
Minimal definition of a server:
```yaml
servers:
  extinction:
    map: Extinction
```

If you only have 1 public IP address available, you **must** set ports for each server:
```yaml
servers:
  extinction:
    ports:
      queryudp: 27015
      gameudp: 7770
      rcon: 32330
```

#### Custom .ini files
Can be configured globally on top level as well as per server. A change in config will then result in a restart of the server.

You can access attributes of your `servers` entry with `.server.attributeName`, see XPMultiplier:
```yaml
servers:
  extinction:
    customConfigMap:
      GameIni: |
        [/Script/ShooterGame.ShooterGameMode]
        bDisableStructurePlacementCollision=True
        PerLevelStatsMultiplier_Player[0]=2.0
        PerLevelStatsMultiplier_Player[4]=2.0
        PerLevelStatsMultiplier_Player[5]=2.0
        PerLevelStatsMultiplier_Player[7]=2.0
        PerLevelStatsMultiplier_DinoTamed[7]=2.0
        PerLevelStatsMultiplier_DinoWild[7]=1
        MatingIntervalMultiplier=0.1
        BabyMatureSpeedMultiplier=25.0
        EggHatchSpeedMultiplier=15.0
        BabyCuddleIntervalMultiplier=0.1
      GameUserSettingsIni: |
        [/Script/ShooterGame.ShooterGameUserSettings]
        Version=5
        [ServerSettings]
        AllowFlyerCarryPvE=True
        AllowThirdPersonPlayer=True
        AlwaysNotifyPlayerLeft=False
        AutoSavePeriodMinutes=15.000000
        ClampResourceHarvestDamage=False
        XPMultiplier={{ .server.xpMultiplier }}
        [...]
```

### Persistence
Ways of configuring persistence. If you don't configure persistence, the game will be downloaded in `emptyDir` and all changes lost when the pod is deleted.
1. provide a `PersistentVolume` for game, cluster and each server
2. provide an `existingClaim` for game, cluster and each server

#### 1. Provide `PersistentVolume`
When you enable persistence, the chart will create the `PersistentVolumeClaim`s for you. It then expects to bind these claims
with volumes of the same name: `<cluster-name>-game`, `<cluster-name>-cluster` and `<cluster-name>-<server-name>`
```yaml
persistence:
  enabled: true
```
Alternatively you can point to existing volumes with `existingVolume`:
```yaml
persistence:
  enabled: true
  game:
    existingVolume: ark-game
  cluster:
    existingVolume: ark-cluster
  save:
    # server name will be appended, e.g. `ark-extinction`
    existingVolume: ark
```

#### 2. Provide `existingClaim`
You can simply provide existing `PersistentVolumeClaims`s for each volume:
```yaml
persistence:
  enabled: true
  game:
    existingClaim: ark-game
  cluster:
    existingClaim: ark-cluster
  save:
    # server name will be appended, e.g. `ark-extinction`
    existingClaim: ark
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
    # limit to max 3 running servers
    requests.cpu: "3"
    requests.memory: 18Gi
    # limit to max 3 running servers
    limits.cpu: "4.5"
    limits.memory: 24Gi
```

## Contributing
* Create issues, create PRs, ... let's make this better together.
* See [Contributing](../../CONTRIBUTING.md)

## Credits
Inspired by
* https://github.com/itzg/minecraft-server-charts
* https://github.com/thmhoag/arkserver
* Icon from [Freepik](https://www.freepik.com) found on [Flaticon](https://www.flaticon.com/)

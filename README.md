Common configuration for hosts.

## Regular zfs snapshots [MIT-21715]

To enable regular zfs snapshots the following variable has to be set:

```sh
zfs_autobackup_enabled=true
```

To list the datasets and defined excludes:

```sh
zfs get -t filesystem autobackup:localsnap
zfs set autobackup:localsnap=false tank/mysql
```

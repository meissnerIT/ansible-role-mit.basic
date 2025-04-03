Common configuration for hosts.

## Regular zfs snapshots [MIT-21715]

[ZFS autobackup](https://github.com/psy0rz/zfs_autobackup) is used for regular snapshots. To enable them the following variable has to be set:

```sh
zfs_autobackup_enabled=true
```

To list the datasets and defined excludes:

```sh
zfs get -t filesystem autobackup:localsnap
sudo zfs set autobackup:localsnap=false tank/mysql

for snap in $(sudo zfs list -t snapshot tank/automysqlbackup | grep "@localsnap-" | awk '{print $1;}'); sudo zfs destroy $snap; end
```

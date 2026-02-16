# stash media manager

When looking for metadata managers for Jellyfin, I found references to
https://github.com/stashapp/stash
as being better suited.

## Install nicely on Linux

Seems they don't offer a distro, only a binary? Dodgy.

The Install instructions are rudimentary. 
On Linux, the install process should be daemonized.

### Make a stash daemon user to own the process.

```
  sudo useradd -r -m -d /var/lib/stash -s /usr/sbin/nologin stash                                                                                                                                                                          
  sudo mkdir -p /var/lib/stash
  sudo chown stash:stash /var/lib/stash
  sudo chmod 750 /var/lib/stash
```

This gives the stash user a home directory at /var/lib/stash (where ~/.stash becomes /var/lib/stash/.stash)

### Get the binary and make it executable.

```
wget https://github.com/stashapp/stash/releases/download/v0.30.1/stash-linux
sudo mv stash-linux /usr/local/bin/stash
sudo chmod a+x /usr/local/bin/stash
```

Prepare the systemd daemon service so it will stop/start as that user

`sudo vi /etc/systemd/system/stash.service`

```
  [Unit]
  Description=Stash Media Server
  After=network.target

  [Service]
  Type=simple
  ExecStart=/usr/local/bin/stash
  Restart=on-failure
  RestartSec=10
  User=stash
  WorkingDirectory=/var/lib/stash

  [Install]
  WantedBy=multi-user.target
```

### Enable and start:
```
   sudo systemctl daemon-reload
   sudo systemctl enable stash
   sudo systemctl start stash
   sudo systemctl status stash
```

`Status` should show `stash is running at http://localhost:9999/`


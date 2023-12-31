[LinuxServer.io's SWAG (nginx reverse proxy)](https://docs.linuxserver.io/general/swag) docker image [has a mod](https://github.com/linuxserver/docker-mods/tree/swag-dashboard) for installing [Goaccess](https://goaccess.io/).

Unfortunately the default configuration for this only reads the first `access.log` file generated by nginx and SWAG rotates this file out pretty agressively. If you have a modest amount of traffic `access.log` may only cover the last 24 hours of traffic which makes the dashboard's range pretty limited.

This repo provides a script [that leverage LinuxServer.io own private/custom mod infrastructure](https://docs.linuxserver.io/general/container-customization) in order to make SWAG read ALL stored `access.log.*` files from its own log volume.

# How Does It Work?

* The provided folders are set as [custom scripts and services](https://docs.linuxserver.io/general/container-customization) in the SWAG container.
* [`preloadLogs.sh`](/src/swag-custom/scripts/preloadLogs.sh) is executed by LISO's custom script init when the container starts
  * The scripts checks for default mod settings and that no data has already been persisted to goaccess -- if both conditions are true then it persists rotated/archived logs files into goaccess
* A custom service makes crontab run
  * Every hour the current `access.log` file is ingested. This makes sure persisted data does not have any gaps in the event you do not access the dashboard frequently.

# Install

* Copy [`/swag-custom`](/src/swag-custom) to your preferred directory. (Best to put it near the same directory SWAG is mounted to for `/config`).
* Change the permissions for the **folders** (`scripts` and `services`) to be owned by `root`.
  * Usually like `chown 0:0 swag-custom/scripts` `chown 0:0 swag-custom/services`
* Changes the permissions for the **contents** of each folder to match the [PUID/PGID](https://docs.linuxserver.io/general/understanding-puid-and-pgid) you have set for your SWAG container
* Mount `scripts` at [`/custom-cont-init.d`](https://docs.linuxserver.io/general/container-customization#custom-scripts) in your SWAG container
* Mount `services` at [`/custom-services.d`](https://docs.linuxserver.io/general/container-customization#custom-services) in your SWAG container

You're done!

## Usage

### Modify Number of Preloaded Logs

[`preloadLogs.sh`](/src/swag-custom/scripts/preloadLogs.sh) will be default ingest the last 100 archived (`access.log.*.gz`) log files found. If you want to ingest less files modify the variable `INGEST_LAST_NUM` in `preloadLogs.sh`. `INGEST_LAST_NUM` is the number of **most recent archvied files** to ingest.

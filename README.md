[LinuxServer.io's SWAG (nginx reverse proxy)](https://docs.linuxserver.io/general/swag) docker image [has a mod](https://github.com/linuxserver/docker-mods/tree/swag-dashboard) for installing [Goaccess](https://goaccess.io/).

Unfortunately the default configuration for this only reads the first `access.log` file generated by nginx and SWAG rotates this file out pretty agressively. If you have a modest amount of traffic `access.log` may only cover the last 24 hours of traffic which makes the dashboard's range pretty limited.

This repo provides scripts/services [that leverage LinuxServer.io own private/custom mod infrastructure](https://docs.linuxserver.io/general/container-customization) in order to make SWAG read ALL stored `access.log.*` files from its own log volume.

# How Does It Work?

* The provided folders are set as [custom scripts and services](https://docs.linuxserver.io/general/container-customization) in the SWAG container. 
* A custom service makes crontab run
* Crontab executes [`combineLogs.sh`](/src/swag-custom/scripts/combineLogs.sh) every 5 minutes
  * The scrip concatenates all logs found under `/config/logs/nginx` in the container (the default location for SWAG logs) into a combined log file at `/dashboard/logs` which SWAG then uses which building the dashboard.

# Install

* Copy [`/swag-custom`](/src/swag-custom) to your preferred directory. (Best to put it near the same directory SWAG is mounted to for `/config`).
* Change the permissions for the **folders** (`scripts` and `services`) to be owned by `root`.
  * Usually like `chown 0:0 swag-custom/scripts` `chown 0:0 swag-custom/services`
* Changes the permissions for the **contents** of each folder to match the [PUID/PGID](https://docs.linuxserver.io/general/understanding-puid-and-pgid) you have set for your SWAG container
* Mount `scripts` at [`/custom-cont-init.d`](https://docs.linuxserver.io/general/container-customization#custom-scripts) in your SWAG container
* Mount `services` at [`/custom-services.d`](https://docs.linuxserver.io/general/container-customization#custom-services) in your SWAG container

You're done! Your combined logs will be updated every 5 minutes for the dashboard to process.

## Usage

### Update Frequency

Modify the [cron expression](https://crontab.guru) in [`addCron.sh`](/src/swag-custom/scripts/addCron.sh) to change the frequency logs are combined at.

### Logs to Combine

[`combineLogs.sh`](/src/swag-custom/scripts/combineLogs.sh) uses `cat` and `zcat` to combine found log files. Modify this command to modify what logs are combined.

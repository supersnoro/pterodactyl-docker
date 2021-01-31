For switching traefik to [lucaslorentz/caddy-docker-proxy](https://github.com/lucaslorentz/caddy-docker-proxy)

<p align="center">
  <img width="400" src="https://raw.githubusercontent.com/BeefBytes/Assets/master/Other/pterodactyl-docker/pterodactyl-docker_logo_png_text_625x347.png">
</p>

# About
There’s a lack of information about setting up and running Pterodactyl Panel inside docker using a reverse proxy. This guide focuses on one of the ways to do that. 

# Getting Started
We’ll be using docker, docker-compose and [lucaslorentz/caddy-docker-proxy](https://github.com/lucaslorentz/caddy-docker-proxy) to generate certificates.

### Requirements
- Basic command line knowledge
- [Docker](https://docs.docker.com/engine/install/ubuntu/)
- [Docker Compose](https://docs.docker.com/compose/install/)

# Installation
**Notes before installation**
- By default the guide assumes you're cloning this repository into `/srv/docker/` directory! 

### Setting up caddy-docker-proxy
<b>Clone repository</b><br />
Start by cloning this repository into `/srv/docker/`. 
```
git clone https://github.com/supersnoro/pterodactyl-docker.git
```

<b>Set variables</b><br />
Navigate to `caddy-reverse-proxy` directory and modify `test@example.com` to your email in the script.

Executing the shell script will create a `caddy-reverse-proxy` container running with the `caddy-reverse-proxy` network that is used in the docker-compose files.

This container is meant to act as a system-wide proxy, hence why it's ran in a separate script.

### Panel
<b>Set variables</b><br />
Navigate to `panel/compose/` directory and rename .env-example to .env. The most important variables to change right now are:

| Variable | Example | Description |
|-|:-:|-|
| PANEL_DOMAIN | panel.example.com | Enter a domain that's behind CloudFlare |
| APP_URL | https://panel.example.com | Same as `PANEL_DOMAIN` but with `https://` included|
| MYSQL_ROOT_PASSWORD | - | Use a password generator to create a strong password |
| MYSQL_PASSWORD | - | Don't reuse your root's password for this, generate a new one |


<b>Initialize database container</b><br />
Allow around a minute or two before starting the panel. Starting it before database is fully initialized may cause errors!
 ```
docker-compose up -d mysql
 ```

<b>Start panel container</b><br />
Allow around two minutes to be fully initialized.
 ```
docker-compose up -d panel
 ```

<b>Create a new user</b><br />
 ```
docker-compose run --rm panel php artisan p:user:make
 ```
Login into the panel using newly created user by navigating to domain you've set in `PANEL_DOMAIN`

<b>Create a new node</b><br />
Navigate to admin control panel and add a new `Location`. Then navigate to `Nodes` and create a node.

| Setting | Set to | Description |
|-|:-:|-|
| FQDN | `WING_DOMAIN` | This is your wing's domain you'll have to specify later in guide. Example: `node.example.com`|
| Behind Proxy | Behind Proxy | Set this to `Behind Proxy` for Traefik to work properly|
| Wing Port | 443 | Change the default port |
| Wing Server File Directory | `DATA_DIR_WING` | By default it should be set to `/srv/docker/pterodactyl-docker/wing/data/wing/servers`. This setting can be changed if desired and is found in `wing/compose/.env-example` |

Rest of the settings can be set as you desire.

### Wing

Follow the same steps from [`Setting up caddy-docker-proxy`](#Setting-up-caddy-docker-proxy) section on your second server for wing.

<b>Setting variables<b><br/>
Navigate to `panel/wing/` directory and rename .env.example to .env and change these variables:

| Variable | Example | Description |
|-|:-:|-|
| WING_DOMAIN | wing.example.com | Enter the domain you want the reverse proxy to use |

<b>Copying wing's config<b><br/>
Navigate to `PANEL_DOMAIN` and find the node you created earlier. Click on `Configuration` tab and copy the contents into `wing/data/config/config.yml`. Sometimes the `remote` url inside `config.yml` may be set to `http://` change it to `https://`.

<b>Generating the config<b><br/>
In the same tab as the config, there is an option to get a command to fetch the config via the wings application. If you would rather use this option, run the following:
```
docker-compose run --rm wing sh -c '[copied command]'
```

<b>Start wing container<b><br/>
 ```
docker-compose up -d wing
 ```

# Known issues
- If running both the wing container and the panel container on the same host, the panel and wing domain names need to be added as aliases to the `caddy-reverse-proxy` container in the `caddy-reverse-proxy` network like so:
```
docker network disconnect caddy-reverse-proxy caddy-reverse-proxy
docker network connect --alias panel.example.com --alias wing.example.com caddy-reverse-proxy caddy-reverse-proxy
```
Be careful not to remove any previously configured aliases.

- Currently the TRUSTED_PROXIES configuration option is set to accept any proxy. It is likely not that bad given that the panel ports are only available to the
`caddy-reverse-proxy` network, but should probably be addressed.

# Credits
- Logo created for this project by Wob - [Dribbble.com/wob](https://dribbble.com/wob)


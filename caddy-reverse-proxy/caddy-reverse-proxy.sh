#!/bin/sh
#   Sets up the reverse proxy docker container to allow setting up Let's Encrypt certs renewal in a single location.

# -e : exit on error
# -u : check for unset variables
# -x : print command before executing
set -eux

echo "Setting up caddy reverse proxy"
# Ensure the caddy-reverse-proxy network exists (so that the reverse proxy can reach other services)
if ! sudo docker network inspect caddy-reverse-proxy >/dev/null 2>&1
then
    sudo docker network create --driver bridge --subnet 172.30.0.0/16 --attachable caddy-reverse-proxy
fi

# Ensure the volume to store the certs exists issued by the reverse proxy
if ! sudo docker volume inspect caddy-reverse-proxy-data >/dev/null 2>&1
then
    sudo docker volume create caddy-reverse-proxy-data
fi


# Pull the reverse proxy app
sudo docker pull lucaslorentz/caddy-docker-proxy:2.3

# Stop+remove reverse proxy if it was running
if sudo docker container inspect caddy-reverse-proxy >/dev/null 2>&1
then
    sudo docker stop caddy-reverse-proxy
    sudo docker rm caddy-reverse-proxy
fi

# Run the reverse proxy
sudo docker run \
    --volume /var/run/docker.sock:/var/run/docker.sock:ro \
    --volume caddy-reverse-proxy-data:/data \
    --network caddy-reverse-proxy \
    --label "caddy.email"="email@example.com" \
    --publish 80:80 \
    --publish 443:443 \
    --restart unless-stopped \
    --name caddy-reverse-proxy \
    --detach \
    lucaslorentz/caddy-docker-proxy:2.3
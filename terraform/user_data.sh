#!/bin/bash
dnf install -y docker
systemctl enable --now docker

docker pull ${docker_image}
docker run -d --name app --restart always -p 80:${container_port} ${docker_image}

#!/bin/bash

DOCKER_USERNAME="dvolkodamov"
IMAGE_NAME="my-demo-app"
VERSION="1.0.0"

docker build -t ${DOCKER_USERNAME}/${IMAGE_NAME}:${VERSION} ./app
docker login -u ${DOCKER_USERNAME}
docker push ${DOCKER_USERNAME}/${IMAGE_NAME}:${VERSION}
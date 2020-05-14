#!/bin/bash

gem build deadpool.gemspec
# docker build -t deadpool .
# docker run --rm -ti deadpool
docker-compose up -d --build

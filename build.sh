#!/bin/bash

gem build deadpool.gemspec
docker-compose up -d --build

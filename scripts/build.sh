#!/bin/bash

# gem build deadpool.gemspec

while [[ "${1:-}" != "" ]]; do
    case $1 in
        -h|--help)
            echo "Usage: build.sh [-h|--help] [-t|--test] [--demo] [-d|--dev]"
            exit 1
            ;;
        --demo)
            docker-compose up -d --build
            ;;
        -t|--test)
            docker build --target test -t deadpool .
            ;;
        -d|--dev)
            docker build --target dev -t deadpool_dev .
            # TODO: pull gem artifact from another build stage and use it to install the 
            # development dependencies
            # echo ""
            # echo "gem build deadpool.gemspec"
            # echo "gem install --development -N deadpool-1.0.0.gem"
            # echo "rake"
            # echo ""
            docker run --rm -ti --entrypoint "/bin/bash" --mount type=bind,source="$(pwd)",target=/opt deadpool_dev:latest
            ;;
        *)
            echo "Unrecognized parameter: $1"
            exit 1
            ;;
    esac
    shift
done



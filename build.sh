#!/bin/bash

set -e

mkdir -p dist

# Build the docker image if it doesn't exist
DOCKER_TAG=$(sha1sum src/Dockerfile)
DOCKER_TAG=${DOCKER_TAG:0:8}
if [ -z "$(docker images -q infocom-frotz:$DOCKER_TAG 2> /dev/null)" ]; then
    echo "Building Docker image"
    docker build --tag infocom-frotz:$DOCKER_TAG - < src/Dockerfile
fi

PORTS="--use-port=freetype --use-port=libjpeg --use-port=libpng --use-port=sdl2 --use-port=sdl2_mixer --use-port=zlib"
COMMON_OPTS="$PORTS -O3"
COMP_OPTS="$COMMON_OPTS -DNO_EXECINFO_H"
LINK_OPTS="$COMMON_OPTS -lidbfs.js --js-library ../src/frotz-library.js --pre-js ../src/preamble.js --profiling-funcs -sALLOW_MEMORY_GROWTH -sASYNCIFY -sENVIRONMENT=web"

rm -f frotz/sfrotz.js
docker run --rm -t \
    -u $(id -u):$(id -g) \
    -v $(pwd):/src \
    infocom-frotz:$DOCKER_TAG \
    /bin/bash -c -e " \\
        emmake make -C frotz --no-print-directory \\
            CFLAGS=\"$COMP_OPTS\" LDFLAGS=\"$LINK_OPTS\" \\
            EXTENSION=.js \\
            sdl \\
    "

./src/makehtml.mjs

cp data/* dist/
cp frotz/sfrotz.* dist/
cp src/static/* dist/
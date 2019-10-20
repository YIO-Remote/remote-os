#!/bin/bash
#
# Script to build the YIO-remote build image.
# Optionally pushes it to the specified Docker registry.
#
#=============================================================

TARGET_REPO=""
BASE_IMAGE_NAME="yio-remote/build"
DOCKEROPS="--pull --no-cache=true"
SKIP_DOCKER_PUSH=true

usage() {
  cat << EOF

Usage: build.sh [-n] [-o Docker build option]
Builds the YIO-remote build image.

Parameters:
   -o: passes on Docker build option. Default: "$DOCKEROPS"
   -p: pushes built image into registry '$TARGET_REPO'

EOF
  exit 0;
}

#=============================================================
#== MAIN starts here...
#=============================================================
while getopts "hop:" optname; do
  case "$optname" in
    "h")
      usage
      ;;
    "p")
      SKIP_DOCKER_PUSH=false
      ;;
    "o")
      DOCKEROPS="$OPTARG"
      ;;
    "?")
      usage;
      exit 1;
      ;;
    *)
    # Should not occur
      echo "Unknown error while processing options inside build-dockerimg.sh"
      ;;
  esac
done

# Proxy settings
PROXY_SETTINGS=""
if [ "${http_proxy}" != "" ]; then
  PROXY_SETTINGS="$PROXY_SETTINGS --build-arg http_proxy=${http_proxy}"
fi

if [ "${https_proxy}" != "" ]; then
  PROXY_SETTINGS="$PROXY_SETTINGS --build-arg https_proxy=${https_proxy}"
fi

if [ "${no_proxy}" != "" ]; then
  PROXY_SETTINGS="$PROXY_SETTINGS --build-arg no_proxy=${no_proxy}"
fi

if [ "$PROXY_SETTINGS" != "" ]; then
  echo "Proxy settings were found and will be used as build arguments: $PROXY_SETTINGS"
fi

# ################## #
# BUILDING THE IMAGE #
# ################## #
DOCKER_IMG_NAME=${TARGET_REPO}${BASE_IMAGE_NAME}

echo "Building image '$DOCKER_IMG_NAME' ..."

BUILD_START=$(date '+%s')
DOCKER_BUILD="$DOCKEROPS $PROXY_SETTINGS -t $DOCKER_IMG_NAME -f Dockerfile ."
echo "#####################################################"
echo "INFO: docker build $DOCKER_BUILD"
echo "#####################################################"
docker build $DOCKER_BUILD || {
  echo "There was an error building the image."
  exit 1
}

# Remove dangling images (intermitten images with tag <none>)
yes | docker image prune > /dev/null

if [ "$SKIP_DOCKER_PUSH" = true ] ; then
  echo "Skipping docker push!"
else
  docker push $DOCKER_IMG_NAME || {
    echo "There was an error pushing the images."
    exit 1
  } 
fi

BUILD_END=$(date '+%s')
BUILD_ELAPSED=`expr $BUILD_END - $BUILD_START`

echo ""

cat << EOF
   YIO-remote build Docker image is ready:

    --> $DOCKER_IMG_NAME

  Build completed in $BUILD_ELAPSED seconds.

EOF
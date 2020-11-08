#!/bin/bash
#
# Build version retrieval script.
# Prints the current version or 'UNKNOWN' if version could not be determined.
#
# 1. see if there is a version file (provided as first argument)
# 2. then try git-describe to retrieve version tag
#    - append '-dirty' if local changes are found
#    - see: https://git-scm.com/docs/git-describe
#    Examples:
#    - build from a version tag: v0.2.0
#    - build from a develop branch which is 16 commits ahead of the latest
#      version tag: v0.2.0-16-g60e1688
#    - build with local modifications: v0.2.0-16-g60e1688-dirty
# 3. otherwise fallback: 'UNKNOWN'
#
# Inspired by:
# https://git.kernel.org/pub/scm/git/git.git/tree/GIT-VERSION-GEN?id=HEAD

VERSION_FILE=$1
DEF_VER=UNKNOWN
LF='
'
cd $(dirname $0)

if test -f "$VERSION_FILE"
then
	BUILD_VERSION=$(cat "$VERSION_FILE") || BUILD_VERSION="$DEF_VER"
# get version from last release tag (e.g. v0.2.0)
# see https://git-scm.com/docs/git-describe
elif BUILD_VERSION=$(git describe --match "v[0-9]*" --tags HEAD 2>/dev/null) &&
	case "$BUILD_VERSION" in
	*$LF*) (exit 1) ;;
	v[0-9]*)
	    # added or modified files? Mark it dirty! (New files are not considered)
		git update-index -q --refresh
		test -z "$(git diff-index --name-only HEAD --)" || BUILD_VERSION="$BUILD_VERSION-dirty" ;;
	esac
then
    # here we could adjust the version from the Git tag. E.g. replace dash with dot
	# BUILD_VERSION=$(echo "$BUILD_VERSION" | sed -e 's/-/./g');
	:
else
	BUILD_VERSION="$DEF_VER"
fi

# strip leading 'v'
BUILD_VERSION=$(expr "$BUILD_VERSION" : v*'\(.*\)')

echo $BUILD_VERSION

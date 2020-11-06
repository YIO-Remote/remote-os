#!/bin/bash
#
# Build wrapper to create a release of the given board in the first argument

SCRIPT_DIR="$( cd "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"

print-board-names() {
    echo "Available board configurations:"
    for file in $SCRIPT_DIR/buildroot-external/configs/*_defconfig; do
        [ -e "$file" ] || continue
        local f="$(basename -- $file)"
        echo "- ${f%_defconfig}"
    done
}

usage() {
  cat << EOF

Usage:
$0 BOARD
  Builds the given BOARD configuration and stores the build output
  in a timestamped logile.

EOF
    print-board-names
  exit 1
}


#------------------------------------------------------------------------------
# Start of script
#------------------------------------------------------------------------------
# check command line arguments
while getopts "h" opt; do
  case ${opt} in
    h )
        usage
        ;;
   \? )
        usage
        ;;
  esac
done

if [ -z "$1" ]; then
    echo "Missing board configuration!"
    print-board-names
    exit 1
fi

#make BR2_JLEVEL=16 $1 2>&1 | tee $1_build_$(date +"%Y%m%d_%H%M%S").log
make $1 2>&1 | tee $1_build_$(date +"%Y%m%d_%H%M%S").log

#!/bin/bash
set -e

echo "Patching Buildroot"
if [[ -d buildroot-patches ]]; then
    for patch_file in buildroot-patches/*.patch; do
        if ! patch --silent -N -d $(dirname $0)/../buildroot -p 1 --dry-run < "${patch_file}" >/dev/null 2>&1; then
            echo "Patch already applied or not applicable: ${patch_file}"
        else
            echo "Applying patch: ${patch_file}"
            patch -N -r - -d $(dirname $0)/../buildroot -p 1 < "${patch_file}";
        fi
   done
fi

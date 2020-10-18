# Buildroot Patches

Custom patching of the Buildroot Git submodule.
This allows applying patches to a specific version without having to clone the
modified Buildroot repository.

Patches are applied alphabetically with [patch-buildroot.sh](../scripts/patch-buildroot.sh).
This is done automatically in the `INIT_BUILDROOT` function in [common.mk](../common.mk),
which is called for example when executing `make menuconfig`.

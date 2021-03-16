#Makefile for the YIO Operating System project

RELEASE_DIR = $(CURDIR)/release

BUILDROOT=$(CURDIR)/buildroot
BUILDROOT_EXTERNAL=$(CURDIR)/buildroot-external
DEFCONFIG_DIR = $(BUILDROOT_EXTERNAL)/configs

TARGETS := $(notdir $(patsubst %_defconfig,%,$(wildcard $(DEFCONFIG_DIR)/*_defconfig)))
TARGETS_CONFIG := $(notdir $(patsubst %_defconfig,%-config,$(wildcard $(DEFCONFIG_DIR)/*_defconfig)))
TARGETS_MENUCONFIG := $(notdir $(patsubst %_defconfig,%-menuconfig,$(wildcard $(DEFCONFIG_DIR)/*_defconfig)))
TARGETS_SDK := $(notdir $(patsubst %_defconfig,%-sdk,$(wildcard $(DEFCONFIG_DIR)/*_defconfig)))

# Set O variable if not already done on the command line
ifneq ("$(origin O)", "command line")
O := $(BUILDROOT)/output
else
override O := $(BUILDROOT)/$(O)
endif

.NOTPARALLEL: $(TARGETS) $(TARGETS_CONFIG) $(TARGETS_MENUCONFIG) all

.PHONY: $(TARGETS) $(TARGETS_CONFIG) $(TARGETS_MENUCONFIG) $(TARGETS_SDK) all clean help

all: $(TARGETS)

$(RELEASE_DIR):
	mkdir -p $(RELEASE_DIR)

$(TARGETS_CONFIG): %-config:
	@echo "Board configuration: $*"
	$(MAKE) -C $(BUILDROOT) BR2_EXTERNAL=$(BUILDROOT_EXTERNAL) "$*_defconfig"

$(TARGETS): %: $(RELEASE_DIR) %-config
	@echo "Building board: $@"
	$(call CLEAR_TOOLCHAIN)
	$(MAKE) -C $(BUILDROOT) BR2_EXTERNAL=$(BUILDROOT_EXTERNAL)
	@echo "Moving images to: $(RELEASE_DIR)"
	mv -f $(O)/images/yio-* $(RELEASE_DIR)/

	# Do not clean when building for one target
ifneq ($(words $(filter $(TARGETS),$(MAKECMDGOALS))), 1)
	@echo "Cleaning $@"
	$(call CLEAR_TOOLCHAIN)
	$(MAKE) -C $(BUILDROOT) BR2_EXTERNAL=$(BUILDROOT_EXTERNAL) clean
endif
	@echo "Finished building board: $@"

$(TARGETS_MENUCONFIG): %-menuconfig:
	@echo "menuconfig $*"
	$(MAKE) -C $(BUILDROOT) BR2_EXTERNAL=$(BUILDROOT_EXTERNAL) "$*_defconfig"
	$(MAKE) -C $(BUILDROOT) BR2_EXTERNAL=$(BUILDROOT_EXTERNAL) menuconfig
	cp "$(DEFCONFIG_DIR)/$*_defconfig" "$(DEFCONFIG_DIR)/$*_defconfig.bak"
	$(MAKE) -C $(BUILDROOT) BR2_EXTERNAL=$(BUILDROOT_EXTERNAL) BR2_DEFCONFIG="$(DEFCONFIG_DIR)/$*_defconfig" savedefconfig

$(TARGETS_SDK): %-sdk:
	@echo "Building external toolchain for $*"
	$(MAKE) -C $(BUILDROOT) BR2_EXTERNAL=$(BUILDROOT_EXTERNAL) "$*_defconfig"
	$(MAKE) -C $(BUILDROOT) BR2_EXTERNAL=$(BUILDROOT_EXTERNAL) sdk


clean:
	$(call CLEAR_TOOLCHAIN)
	$(MAKE) -C $(BUILDROOT) BR2_EXTERNAL=$(BUILDROOT_EXTERNAL) clean


help:
	@echo "Supported targets: $(TARGETS)"
	@echo "Run 'make <target>' to build a target image and keep build artefacts."
	@echo "Run 'make all' to build all target images."
	@echo "Run 'make clean' to clean the build output."
	@echo "Run 'make <target>-config' to initialize buildroot for a target."
	@echo "Run 'make <target>-menuconfig' to configure a target."
	@echo "Run 'make <target>-sdk' to build the external toolchain."

define CLEAR_TOOLCHAIN
	rm -f $(BUILDROOT_EXTERNAL)/.toolchain-ready
endef

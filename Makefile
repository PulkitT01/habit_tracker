# HabitTracker — SwiftPM menu-bar app (no Xcode project). See README.md.
include version.env

# Build with Xcode's toolchain (no Xcode project is involved). The Command Line Tools for macOS 27
# lack the SwiftUI macro plugin that @State needs, their `swift test` intermittently fails to load
# TestingMacros (swift-build #1870), and their no-change builds recompile everything (#1861).
# Override with `make DEVELOPER_DIR=...`.
XCODE_DEVELOPER_DIR := /Applications/Xcode.app/Contents/Developer
ifneq ($(wildcard $(XCODE_DEVELOPER_DIR)),)
DEVELOPER_DIR ?= $(XCODE_DEVELOPER_DIR)
export DEVELOPER_DIR
else
$(warning Xcode.app not found: building with the Command Line Tools, which can't compile SwiftUI's @State on macOS 27)
endif

APP_DIR := .build/app
INSTALL_DIR := $(HOME)/Applications
DEV_APP := $(APP_DIR)/$(APP_NAME)Dev.app
LSREGISTER := /System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister

# Quits a running app by executable name, waits up to 5 s, and stops if it is still running
# (otherwise `open` would just re-activate the old copy).
define quit_app
	@pkill -x $(1) || true
	@for _ in $$(seq 50); do pgrep -x $(1) >/dev/null || break; sleep 0.1; done
	@if pgrep -x $(1) >/dev/null; then echo "$(1) is still running; quit it and try again" >&2; exit 1; fi
endef

.PHONY: build test bundle run install clean

## build: debug build of all targets
build:
	swift build

## test: run the HabitCore unit tests (Swift Testing)
test:
	swift test

## bundle: release .app in .build/app/HabitTracker.app (ad-hoc signed)
bundle:
	Scripts/package_app.sh release

## run: build and launch "HabitTracker Dev" (separate bundle id and data folder)
run:
	Scripts/package_app.sh dev
	$(call quit_app,$(APP_NAME)Dev)
	$(LSREGISTER) -f "$(DEV_APP)"
	open "$(DEV_APP)"

## install: copy the release app to ~/Applications, replacing and relaunching any running copy
install: bundle
	$(call quit_app,$(APP_NAME))
	mkdir -p "$(INSTALL_DIR)"
	rm -rf "$(INSTALL_DIR)/$(APP_NAME).app"
	ditto "$(APP_DIR)/$(APP_NAME).app" "$(INSTALL_DIR)/$(APP_NAME).app"
	$(LSREGISTER) -f "$(INSTALL_DIR)/$(APP_NAME).app"
	open "$(INSTALL_DIR)/$(APP_NAME).app"
	@echo "Installed $(INSTALL_DIR)/$(APP_NAME).app"

## clean: remove build products
clean:
	swift package clean
	rm -rf $(APP_DIR)

.DEFAULT_GOAL := debug

XCODEBUILD ?= xcodebuild
SWIFTLINT ?= swiftlint

BUILD_DIR ?= $(CURDIR)/build
DIST_DIR ?= $(CURDIR)/dist
DESTINATION ?= platform=macOS,arch=$(shell uname -m)

DEBUG_APP := $(BUILD_DIR)/debug/Build/Products/Debug/VizCE.app
RELEASE_APP := $(BUILD_DIR)/release/Build/Products/Release/VizCE.app

.PHONY: build debug release test lint clean

build: debug

debug:
	"$(XCODEBUILD)" -project "VizCE.xcodeproj" -scheme "VizCE Debug" \
		-configuration Debug -destination "$(DESTINATION)" \
		-derivedDataPath "$(BUILD_DIR)/debug" \
		build
	rm -rf "$(DIST_DIR)/Debug/VizCE.app"
	mkdir -p "$(DIST_DIR)/Debug"
	ditto "$(DEBUG_APP)" "$(DIST_DIR)/Debug/VizCE.app"

release:
	"$(XCODEBUILD)" -project "VizCE.xcodeproj" -scheme "VizCE Release" \
		-configuration Release -destination "$(DESTINATION)" \
		-derivedDataPath "$(BUILD_DIR)/release" \
		build
	rm -rf "$(DIST_DIR)/Release/VizCE.app"
	mkdir -p "$(DIST_DIR)/Release"
	ditto "$(RELEASE_APP)" "$(DIST_DIR)/Release/VizCE.app"

test:
	"$(XCODEBUILD)" -project "Tests/VizCETests.xcodeproj" -scheme "VizCETests" \
		-configuration Debug -destination "$(DESTINATION)" \
		-derivedDataPath "$(BUILD_DIR)/tests" \
		test

lint:
	"$(SWIFTLINT)" lint --config ".swiftlint.yml" --force-exclude "VizCE" "Tests"

clean:
	rm -rf "$(BUILD_DIR)" "$(DIST_DIR)"

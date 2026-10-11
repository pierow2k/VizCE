.DEFAULT_GOAL := build

XCODEBUILD ?= xcodebuild
SWIFTLINT ?= swiftlint
BUILD_DIR ?= $(CURDIR)/build
DESTINATION ?= platform=macOS,arch=$(shell uname -m)
CODE_SIGNING_ALLOWED ?= NO

.PHONY: build test lint

build:
	"$(XCODEBUILD)" -project "VizCE.xcodeproj" -scheme "VizCE Debug" \
		-configuration Debug -destination "$(DESTINATION)" \
		-derivedDataPath "$(BUILD_DIR)/app" \
		"CODE_SIGNING_ALLOWED=$(CODE_SIGNING_ALLOWED)" build

test:
	"$(XCODEBUILD)" -project "Tests/VizCETests.xcodeproj" -scheme "VizCETests" \
		-configuration Debug -destination "$(DESTINATION)" \
		-derivedDataPath "$(BUILD_DIR)/tests" \
		"CODE_SIGNING_ALLOWED=$(CODE_SIGNING_ALLOWED)" test

lint:
	"$(SWIFTLINT)" lint --config ".swiftlint.yml" --force-exclude "VizCE" "Tests"

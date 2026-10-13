
# --------------------------------------------------------- [PROJECT VARIABLES]
APP_NAME := VizCE
APP_VERSION ?= 3.0.0
BUILD_NUMBER ?= 1

.DEFAULT_GOAL := debug

PROJECT ?= VizCE.xcodeproj
DEBUG_SCHEME ?= VizCE Debug
RELEASE_SCHEME ?= VizCE Release
TEST_PROJECT ?= Tests/VizCETests.xcodeproj
TEST_SCHEME ?= VizCETests

XCODEBUILD ?= xcodebuild
SWIFTLINT ?= swiftlint
SWIFT ?= swift

BUILD_DIR ?= $(CURDIR)/build
DIST_DIR ?= $(CURDIR)/dist
HOST_ARCH ?= $(shell uname -m)

DEBUG_DERIVED_DATA := $(BUILD_DIR)/debug
RELEASE_DERIVED_DATA := $(BUILD_DIR)/release
TEST_DERIVED_DATA := $(BUILD_DIR)/tests

DEBUG_APP := $(DEBUG_DERIVED_DATA)/Build/Products/Debug/$(APP_NAME).app
RELEASE_APP := $(RELEASE_DERIVED_DATA)/Build/Products/Release/$(APP_NAME).app

DEBUG_DESTINATION ?= platform=macOS,arch=$(HOST_ARCH)
RELEASE_DESTINATION ?= generic/platform=macOS

DIST_DEBUG_APP := $(DIST_DIR)/Debug/$(APP_NAME).app
DIST_RELEASE_APP := $(DIST_DIR)/Release/$(APP_NAME).app
RELEASE_ZIP = $(DIST_DIR)/$(APP_NAME)-$(APP_VERSION)-macOS-universal.zip

RELEASE_EXECUTABLE := $(RELEASE_APP)/Contents/MacOS/$(APP_NAME)

# Prefix for build messages, including optional terminal color.
MESSAGE_PREFIX := $(shell \
	if [ "$$(tput colors 2>/dev/null || echo 0)" -ge 8 ]; then \
		printf "\033[34;1m▶\033[0m"; \
	else \
		printf "▶"; \
	fi)

define print_plist_value
	@printf "%s %-20s %s\n" "$(MESSAGE_PREFIX)" "$(1):" \
		"$$(/usr/libexec/PlistBuddy -c 'Print :$(2)' "$(DIST_RELEASE_APP)/Contents/Info.plist")"
endef

# ------------------------------------------------------------------- [TARGETS]
.PHONY: build clean debug help inspect lint package release test test-foundation

build: debug

clean: #@HELP Remove build and distribution directories
	@echo "-$(MESSAGE_PREFIX) Cleaning build and distribution directories..."
	@case "$(abspath $(BUILD_DIR))" in \
		/|"$(CURDIR)") echo "Unsafe BUILD_DIR"; exit 1;; \
	esac
	@case "$(abspath $(DIST_DIR))" in \
		/|"$(CURDIR)") echo "Unsafe DIST_DIR"; exit 1;; \
	esac
	rm -rf "$(BUILD_DIR)" "$(DIST_DIR)"

debug: #@HELP Build the debug version of the app
	@echo "-$(MESSAGE_PREFIX) Building debug version of $(APP_NAME)..."
	"$(XCODEBUILD)" \
		-project "$(PROJECT)" \
		-scheme "$(DEBUG_SCHEME)" \
		-configuration Debug \
		-destination "$(DEBUG_DESTINATION)" \
		-derivedDataPath "$(DEBUG_DERIVED_DATA)" \
		MARKETING_VERSION="$(APP_VERSION)" \
		CURRENT_PROJECT_VERSION="$(BUILD_NUMBER)" \
		build
	rm -rf "$(DIST_DEBUG_APP)"
	mkdir -p "$(dir $(DIST_DEBUG_APP))"
	ditto "$(DEBUG_APP)" "$(DIST_DEBUG_APP)"

help: #@HELP Print available targets
	@printf '\n%s TARGETS FOR MAKE:\n' '$(MESSAGE_PREFIX)'
	@awk '/^[[:alnum:]_-]+:/ && /# *@HELP/ { \
		split($$0, target, ":"); \
		split($$0, description, /# *@HELP[[:space:]]*/); \
		printf "%-12s %s\n", target[1], description[2]; \
	}' $(MAKEFILE_LIST) | sort

inspect: #@HELP Inspect the release application
	$(call print_plist_value,Bundle identifier,CFBundleIdentifier)
	$(call print_plist_value,Version,CFBundleShortVersionString)
	$(call print_plist_value,Build number,CFBundleVersion)

lint: #@HELP Run SwiftLint checks
	@echo "-$(MESSAGE_PREFIX) Running SwiftLint checks on $(APP_NAME)..."
	"$(SWIFTLINT)" lint \
		--config ".swiftlint.yml" \
		--force-exclude \
		"VizCE" "Tests"

package: release #@HELP Build a zipped release version of the app
	@echo "-$(MESSAGE_PREFIX) Packaging $(APP_NAME) v$(APP_VERSION)..."
	@set -e; \
		tmp="$(RELEASE_ZIP).tmp"; \
		trap 'rm -f "$$tmp"' 0; \
		rm -f "$$tmp"; \
		ditto -c -k --sequesterRsrc --keepParent \
			"$(DIST_RELEASE_APP)" "$$tmp"; \
		mv -f "$$tmp" "$(RELEASE_ZIP)"
	@echo "-$(MESSAGE_PREFIX) Creating checksum for Zip File..."
	@cd "$(DIST_DIR)" && \
		shasum -a 256 "$(notdir $(RELEASE_ZIP))" \
			> "$(notdir $(RELEASE_ZIP)).sha256"

release: #@HELP Build the universal release version of the app
	@echo "-$(MESSAGE_PREFIX) Building release version of $(APP_NAME)..."
	"$(XCODEBUILD)" \
		-project "$(PROJECT)" \
		-scheme "$(RELEASE_SCHEME)" \
		-configuration Release \
		-destination "$(RELEASE_DESTINATION)" \
		-derivedDataPath "$(RELEASE_DERIVED_DATA)" \
		MARKETING_VERSION="$(APP_VERSION)" \
		CURRENT_PROJECT_VERSION="$(BUILD_NUMBER)" \
		ARCHS="arm64 x86_64" \
		ONLY_ACTIVE_ARCH=NO \
		build
	@echo "-$(MESSAGE_PREFIX) Verifying arm64 compatibility..."
	lipo -verify_arch arm64 "$(RELEASE_EXECUTABLE)"
	@echo "-$(MESSAGE_PREFIX) Verifying x86_64 compatibility..."
	lipo -verify_arch x86_64 "$(RELEASE_EXECUTABLE)"
	rm -rf "$(DIST_RELEASE_APP)"
	mkdir -p "$(dir $(DIST_RELEASE_APP))"
	ditto "$(RELEASE_APP)" "$(DIST_RELEASE_APP)"

test-foundation: #@HELP Run updater dependency regression tests
	"$(SWIFT)" test --package-path Vendor/AlinFoundation \
		--scratch-path "$(BUILD_DIR)/foundation-tests"

test: test-foundation #@HELP Run unit tests
	@echo "-$(MESSAGE_PREFIX) Running unit tests on $(APP_NAME)..."
	"$(XCODEBUILD)" \
		-project "$(TEST_PROJECT)" \
		-scheme "$(TEST_SCHEME)" \
		-configuration Debug \
		-destination "$(DEBUG_DESTINATION)" \
		-derivedDataPath "$(TEST_DERIVED_DATA)" \
		test

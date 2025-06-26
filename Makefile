# Microui Build System

VERSION ?= $(shell cat .version 2>/dev/null || echo "latest")
PREFIX ?= /usr/local
PATH ?= /usr/local/bin:$(PATH)
BUILD_TYPE ?= Release

# OS Detection
OS_NAME := $(shell uname -o 2>/dev/null || uname -s)

# Set OpenGL flags based on OS
ifeq ($(OS_NAME),Msys)
    GLFLAG := -lopengl32
    SDL2_CFLAGS := 
    SDL2_LIBS := -lSDL2 -lSDL2main
else ifeq ($(OS_NAME),Darwin)
    GLFLAG := -framework OpenGL
    SDL2_CFLAGS := -I/opt/homebrew/include
    SDL2_LIBS := $(shell sdl2-config --libs 2>/dev/null || echo "-L/opt/homebrew/lib -lSDL2")
else
    GLFLAG := -lGL
    SDL2_CFLAGS := $(shell sdl2-config --cflags 2>/dev/null || echo "")
    SDL2_LIBS := $(shell sdl2-config --libs 2>/dev/null || echo "-lSDL2")
endif

CC ?= gcc
AR ?= ar
CFLAGS ?= -std=c11 -Isrc -Iinclude $(SDL2_CFLAGS) -Wall -pedantic
LDFLAGS ?= $(SDL2_LIBS) $(GLFLAG) -lm
DEBUG_FLAGS ?= -g -DDEBUG -O0
RELEASE_FLAGS ?= -O3
TEST_FLAGS ?= -DTEST_MODE

TARGET ?= microui
LIB_TARGET ?= lib$(TARGET).a

HEADERS = \
	include/microui.h \
	include/renderer.h \
	include/client.h \
	include/server.h \
	include/window.h

SOURCES = \
	src/microui.c \
	src/renderer.c \
	src/client.c \
	src/server.c \
	src/window.c

MAIN = src/main.c

DIST_DIR ?= dist
DIST_BIN_DIR = $(DIST_DIR)/bin
DIST_LIB_DIR = $(DIST_DIR)/lib
DIST_OBJ_DIR = $(DIST_DIR)/obj
DIST_TEST_DIR = $(DIST_DIR)/test
DIST_SHARE_DIR = $(DIST_DIR)/share
DIST_INCLUDE_DIR = $(DIST_DIR)/include

PUBLISH_DIR = publish
PUBLISH_BIN_DIR = $(PUBLISH_DIR)/bin
PUBLISH_LIB_DIR = $(PUBLISH_DIR)/lib
PUBLISH_SHARE_DIR = $(PUBLISH_DIR)/share
PUBLISH_INCLUDE_DIR = $(PUBLISH_DIR)/include

ARTIFACTS_DIR = artifacts

BIN_DIR = $(PREFIX)/bin
INCLUDE_DIR = $(PREFIX)/include/$(TARGET)
LIB_DIR = $(PREFIX)/lib/$(TARGET)
SHARE_DIR = $(PREFIX)/share/$(TARGET)
LOG_DIR = $(PREFIX)/var/log/$(TARGET)

OBJECTS = $(SOURCES:.c=.o)
MAIN_OBJ = $(MAIN:.c=.o)
OBJ_FILES = $(addprefix $(DIST_OBJ_DIR)/, $(notdir $(OBJECTS)))
MAIN_OBJ_FILE = $(addprefix $(DIST_OBJ_DIR)/, $(notdir $(MAIN_OBJ)))

TEST_SOURCES = tests/integration_tests.c tests/unit_tests.c tests/performance_tests.c
TEST_TARGETS = $(DIST_TEST_DIR)/integration_tests $(DIST_TEST_DIR)/unit_tests $(DIST_TEST_DIR)/performance_tests
TEST_LIBS = ""

SHARE_FILES = microui.conf

.PHONY: \
	all \
	lib \
	debug \
	release \
	static \
	dependencies \
	dev-dependencies \
	share \
	headers \
	check \
	lint \
	test-unit \
	test-integration \
	test-performance \
	install \
	install-lib \
	uninstall \
	publish \
	clean \
	clean-full \
	help \
	version \
	patch \
	minor \
	major \
	ldd

all: $(DIST_BIN_DIR)/$(TARGET) $(DIST_LIB_DIR)/$(LIB_TARGET) headers share

lib: $(DIST_LIB_DIR)/$(LIB_TARGET) headers

debug: CFLAGS += $(DEBUG_FLAGS)
debug: $(DIST_BIN_DIR)/$(TARGET) $(DIST_LIB_DIR)/$(LIB_TARGET) headers share

release: CFLAGS += $(RELEASE_FLAGS)
release: $(DIST_BIN_DIR)/$(TARGET) $(DIST_LIB_DIR)/$(LIB_TARGET) headers share

static:
	@echo "🔗 Building with static linking for $(OS_NAME)..."
ifeq ($(OS_NAME),Msys)
	$(MAKE) LDFLAGS="-static -lSDL2main -lSDL2 -lopengl32 -lm -lwinmm -lole32 -loleaut32 -limm32 -lversion -luuid -ladvapi32 -lsetupapi -lshell32 -ldinput8" $(DIST_BIN_DIR)/$(TARGET) $(DIST_LIB_DIR)/$(LIB_TARGET) headers share
else ifeq ($(OS_NAME),Darwin)
	$(MAKE) LDFLAGS="/opt/homebrew/lib/libSDL2.a /opt/homebrew/lib/libSDL2main.a -framework OpenGL -framework CoreGraphics -framework CoreServices -framework ForceFeedback -framework Cocoa -framework Carbon -framework IOKit -framework CoreAudio -framework CoreFoundation -framework CoreHaptics -framework GameController -framework Metal -framework AudioToolbox -framework AVFoundation -framework CoreVideo -framework QuartzCore -lm -liconv" $(DIST_BIN_DIR)/$(TARGET) $(DIST_LIB_DIR)/$(LIB_TARGET) headers share
else
	$(MAKE) LDFLAGS="-static -lSDL2main -lSDL2 -lGL -lm -lpthread -ldl -lasound -lpulse -lX11 -lXext -lXcursor -lXinerama -lXi -lXrandr -lXss -lXxf86vm -lwayland-egl -lwayland-client -lwayland-cursor -lxkbcommon" $(DIST_BIN_DIR)/$(TARGET) $(DIST_LIB_DIR)/$(LIB_TARGET) headers share
endif

dev-dependencies:
	@echo "🛠️  Installing development dependencies for $(OS_NAME)..."
ifeq ($(OS_NAME),Msys)
	@echo "📦 Please install development tools for Windows manually:"
	@echo "   - Visual Studio Build Tools or MinGW-w64"
	@echo "   - clang-format (via LLVM installer)"
	@echo "   - cppcheck (download from http://cppcheck.sourceforge.net/)"
else ifeq ($(OS_NAME),Darwin)
	@echo "🍺 Installing development tools via Homebrew..."
	@which brew >/dev/null 2>&1 || (echo "❌ Homebrew not found. Please install it first." && exit 1)
	@brew install clang-format cppcheck
	@echo "✅ Development tools installed successfully"
	@echo "   Note: Xcode Command Line Tools should already provide build-essential"
else
	@echo "🐧 Installing development tools for Linux..."
	@sudo apt-get update -y
	@sudo apt-get install -y build-essential clang-format cppcheck
	@echo "✅ Development tools installed successfully"
endif

dependencies:
	@echo "🔧 Installing dependencies for $(OS_NAME)..."
ifeq ($(OS_NAME),Msys)
	@echo "📦 Please install SDL2 for Windows manually"
	@echo "   Download from: https://www.libsdl.org/download-2.0.php"
else ifeq ($(OS_NAME),Darwin)
	@echo "🍺 Installing SDL2 via Homebrew..."
	@which brew >/dev/null 2>&1 || (echo "❌ Homebrew not found. Please install it first." && exit 1)
	@brew install sdl2
	@echo "✅ SDL2 installed successfully"
else
	@echo "🐧 Installing SDL2 for Linux..."
	@sudo apt-get update -y
	@sudo apt-get install libsdl2-dev -y
	@echo "✅ SDL2 development libraries installed successfully"
endif

share: | $(DIST_SHARE_DIR)
	@echo "⚙️  Configuring project..."
	@cp config/*.conf $(DIST_SHARE_DIR)/
	@echo "✅ Configuration files copied to $(DIST_SHARE_DIR)/"

headers: | $(DIST_INCLUDE_DIR)
	@echo "📋 Copying headers to dist/include/..."
	@cp $(HEADERS) $(DIST_INCLUDE_DIR)/
	@echo "✅ Headers copied to $(DIST_INCLUDE_DIR)/"

$(DIST_BIN_DIR)/$(TARGET): $(OBJ_FILES) $(MAIN_OBJ_FILE) | $(DIST_BIN_DIR)
	@echo "🔗 Linking objects into executable $(TARGET)..."
	@echo "   Objects: $(notdir $(OBJ_FILES)) $(notdir $(MAIN_OBJ_FILE))"
	$(CC) $(OBJ_FILES) $(MAIN_OBJ_FILE) -o $@ $(LDFLAGS)
	@echo "✅ Built executable $(TARGET) successfully"

$(DIST_LIB_DIR)/$(LIB_TARGET): $(OBJ_FILES) | $(DIST_LIB_DIR)
	@echo "📚 Creating static library $(LIB_TARGET)..."
	@echo "   Archive: $(notdir $(OBJ_FILES))"
	$(AR) rcs $@ $(OBJ_FILES)
	@echo "✅ Built static library $(LIB_TARGET) successfully"

$(DIST_OBJ_DIR)/%.o: src/%.c $(HEADERS) | $(DIST_OBJ_DIR)
	@echo "🔨 Compiling $< → $(notdir $@)"
	$(CC) $(CFLAGS) -c $< -o $@

test-unit: $(DIST_TEST_DIR)/unit_tests share
	@echo "🧪 Running unit tests..."
	@mkdir -p $(DIST_TEST_DIR)
	@cd $(DIST_TEST_DIR) && ./unit_tests

test-integration: $(DIST_TEST_DIR)/integration_tests share
	@echo "🔬 Running integration tests..."
	@mkdir -p $(DIST_TEST_DIR)
	@cd $(DIST_TEST_DIR) && ./integration_tests

test-performance: $(DIST_TEST_DIR)/performance_tests share
	@echo "⚡ Running performance tests..."
	@mkdir -p $(DIST_TEST_DIR)
	@cd $(DIST_TEST_DIR) && ./performance_tests

$(DIST_TEST_DIR)/unit_tests: tests/unit_tests.c $(HEADERS) | $(DIST_TEST_DIR)
	@echo "🔨 Building unit tests..."
	$(CC) $(CFLAGS) $(TEST_FLAGS) tests/unit_tests.c -o $@ $(LDFLAGS)

$(DIST_TEST_DIR)/integration_tests: tests/integration_tests.c $(HEADERS) | $(DIST_TEST_DIR)
	@echo "🔨 Building integration tests..."
	$(CC) $(CFLAGS) $(TEST_FLAGS) tests/integration_tests.c -o $@ $(LDFLAGS)

$(DIST_TEST_DIR)/performance_tests: tests/performance_tests.c $(HEADERS) | $(DIST_TEST_DIR)
	@echo "🔨 Building performance tests..."
	$(CC) $(CFLAGS) $(TEST_FLAGS) tests/performance_tests.c -o $@ $(LDFLAGS)

check: $(SOURCES) $(HEADERS)
	@echo "🔍 Running static analysis..."
	@cppcheck --enable=all --std=c11 src/ include/ tests/

lint: $(SOURCES) $(HEADERS)
	@echo "🔍 Checking code style..."
	@clang-format --dry-run --Werror src/*.c include/*.h tests/*.c

ldd: $(DIST_BIN_DIR)/$(TARGET)
	@echo "🔍 Checking executable dependencies..."
ifeq ($(OS_NAME),Darwin)
	@otool -L $(DIST_BIN_DIR)/$(TARGET)
else ifeq ($(OS_NAME),Msys)
	@objdump -p $(DIST_BIN_DIR)/$(TARGET) | grep "DLL Name"
else
	@ldd $(DIST_BIN_DIR)/$(TARGET)
endif

$(DIST_BIN_DIR):
	@mkdir -p $(DIST_BIN_DIR)

$(DIST_LIB_DIR):
	@mkdir -p $(DIST_LIB_DIR)

$(DIST_OBJ_DIR):
	@mkdir -p $(DIST_OBJ_DIR)

$(DIST_TEST_DIR):
	@mkdir -p $(DIST_TEST_DIR)

$(DIST_SHARE_DIR):
	@mkdir -p $(DIST_SHARE_DIR)

$(DIST_INCLUDE_DIR):
	@mkdir -p $(DIST_INCLUDE_DIR)

publish: $(DIST_BIN_DIR)/$(TARGET) $(DIST_LIB_DIR)/$(LIB_TARGET) headers share | $(PUBLISH_BIN_DIR) $(PUBLISH_LIB_DIR) $(PUBLISH_SHARE_DIR) $(PUBLISH_INCLUDE_DIR) $(ARTIFACTS_DIR)
	@echo "📦 Preparing publish package..."
	@cp $(DIST_BIN_DIR)/$(TARGET) $(PUBLISH_BIN_DIR)/
	@cp $(DIST_LIB_DIR)/$(LIB_TARGET) $(PUBLISH_LIB_DIR)/
	@cp $(HEADERS) $(PUBLISH_INCLUDE_DIR)/
	@cp $(DIST_SHARE_DIR)/*.conf $(PUBLISH_SHARE_DIR)/
	@echo "📋 Creating archive..."
	@cd $(PUBLISH_DIR) && tar -czf ../$(ARTIFACTS_DIR)/$(TARGET)-$(VERSION).tar.gz bin/ lib/ include/ share/
	@echo "✅ Publish package created: $(ARTIFACTS_DIR)/$(TARGET)-$(VERSION).tar.gz"

$(PUBLISH_BIN_DIR):
	@mkdir -p $(PUBLISH_BIN_DIR)

$(PUBLISH_LIB_DIR):
	@mkdir -p $(PUBLISH_LIB_DIR)

$(PUBLISH_SHARE_DIR):
	@mkdir -p $(PUBLISH_SHARE_DIR)

$(PUBLISH_INCLUDE_DIR):
	@mkdir -p $(PUBLISH_INCLUDE_DIR)

$(ARTIFACTS_DIR):
	@mkdir -p $(ARTIFACTS_DIR)

install: $(DIST_BIN_DIR)/$(TARGET) $(DIST_LIB_DIR)/$(LIB_TARGET)
	@echo "📥 Installing to $(PREFIX)..."
	@install -d $(DESTDIR)$(BIN_DIR)
	@install -d $(DESTDIR)$(LIB_DIR)
	@install -d $(DESTDIR)$(INCLUDE_DIR)
	@install -d $(DESTDIR)$(SHARE_DIR)
	@install -d $(DESTDIR)$(LOG_DIR)
	@install -m 755 $(DIST_BIN_DIR)/$(TARGET) $(DESTDIR)$(BIN_DIR)/
	@install -m 644 $(DIST_LIB_DIR)/$(LIB_TARGET) $(DESTDIR)$(LIB_DIR)/
	@install -m 644 $(HEADERS) $(DESTDIR)$(INCLUDE_DIR)/
	@install -m 644 config/*.conf $(DESTDIR)$(SHARE_DIR)/
	@echo "✅ Installation completed!"
	@echo "📁 Binary: $(BIN_DIR)/$(TARGET)"
	@echo "📁 Library: $(LIB_DIR)/$(LIB_TARGET)"
	@echo "📁 Headers: $(INCLUDE_DIR)/"
	@echo "📁 Config: $(SHARE_DIR)/"
	@echo "📁 Logs: $(LOG_DIR)/"

install-lib: $(DIST_LIB_DIR)/$(LIB_TARGET)
	@echo "📚 Installing library to $(PREFIX)..."
	@install -d $(DESTDIR)$(LIB_DIR)
	@install -d $(DESTDIR)$(INCLUDE_DIR)
	@install -m 644 $(DIST_LIB_DIR)/$(LIB_TARGET) $(DESTDIR)$(LIB_DIR)/
	@install -m 644 $(HEADERS) $(DESTDIR)$(INCLUDE_DIR)/
	@echo "✅ Library installation completed!"
	@echo "📁 Library: $(LIB_DIR)/$(LIB_TARGET)"
	@echo "📁 Headers: $(INCLUDE_DIR)/"

uninstall:
	@echo "🗑️  Uninstalling from $(PREFIX)..."
	@rm -f $(DESTDIR)$(BIN_DIR)/$(TARGET)
	@rm -f $(DESTDIR)$(LIB_DIR)/$(LIB_TARGET)
	@rm -rf $(DESTDIR)$(INCLUDE_DIR)
	@rm -rf $(DESTDIR)$(SHARE_DIR)
	@echo "✅ Uninstallation completed!"

# Version management targets
version:
	@echo "$(VERSION)"

patch:
	@echo "🔧 Bumping patch version..."
	@current_version=$$(cat .version); \
	major=$$(echo $$current_version | cut -d. -f1); \
	minor=$$(echo $$current_version | cut -d. -f2); \
	patch=$$(echo $$current_version | cut -d. -f3); \
	new_patch=$$((patch + 1)); \
	new_version="$$major.$$minor.$$new_patch"; \
	echo "$$new_version" > .version; \
	echo "✅ Version bumped from $$current_version to $$new_version"

minor:
	@echo "🔧 Bumping minor version..."
	@current_version=$$(cat .version); \
	major=$$(echo $$current_version | cut -d. -f1); \
	minor=$$(echo $$current_version | cut -d. -f2); \
	new_minor=$$((minor + 1)); \
	new_version="$$major.$$new_minor.0"; \
	echo "$$new_version" > .version; \
	echo "✅ Version bumped from $$current_version to $$new_version"

major:
	@echo "🔧 Bumping major version..."
	@current_version=$$(cat .version); \
	major=$$(echo $$current_version | cut -d. -f1); \
	new_major=$$((major + 1)); \
	new_version="$$new_major.0.0"; \
	echo "$$new_version" > .version; \
	echo "✅ Version bumped from $$current_version to $$new_version"

clean:
	@echo "🧹 Cleaning build artifacts..."
	@rm -rf $(DIST_DIR)
	@rm -rf $(PUBLISH_DIR)
	@echo "✅ Cleanup completed!"

clean-full:
	@echo "🧹 Cleaning all artifacts and environment files..."
	@rm -rf $(DIST_DIR)
	@rm -rf $(PUBLISH_DIR)
	@rm -rf $(ARTIFACTS_DIR)
	@rm -f .env
	@echo "✅ Full cleanup completed!"

help:
	@echo "🚀 Microui Build System"
	@echo ""
	@echo "📋 Available targets:"
	@echo "  all              - Build the main binary and static library"
	@echo "  lib              - Build only the static library (without main.c)"
	@echo "  debug            - Build with debug symbols"
	@echo "  release          - Build with release optimizations"
	@echo "  static           - Build with static linking (no SDL2 runtime dependencies)"
	@echo "  dependencies     - Install system dependencies (SDL2)"
	@echo "  dev-dependencies - Install development tools (build-essential, clang-format, cppcheck)"
	@echo "  share            - Copy configuration files to dist directory"
	@echo "  headers          - Copy header files to dist directory"
	@echo "  check            - Run static analysis"
	@echo "  lint             - Run code style checker"
	@echo "  ldd              - Check executable dependencies (otool/ldd/objdump)"
	@echo "  test-unit        - Run unit tests"
	@echo "  test-integration - Run integration tests"
	@echo "  test-performance - Run performance tests"
	@echo "  install          - Install binary and library to system (use PREFIX=path to customize)"
	@echo "  install-lib      - Install only library and headers to system"
	@echo "  publish          - Create a distributable package with bin, lib, include, and share files"
	@echo "  uninstall        - Remove from system"
	@echo "  clean            - Remove build artifacts (keeps artifacts/ and .env files)"
	@echo "  clean-full       - Remove all artifacts including artifacts/ and .env files"
	@echo "  version          - Display current version"
	@echo "  patch            - Bump patch version (x.y.z -> x.y.z+1)"
	@echo "  minor            - Bump minor version (x.y.z -> x.y+1.0)"
	@echo "  major            - Bump major version (x.y.z -> x+1.0.0)"
	@echo "  help             - Show this help"
	@echo ""
	@echo "🖥️  Detected OS: $(OS_NAME)"
	@echo "🔗 OpenGL flags: $(GLFLAG)"
	@echo "📦 SDL2 flags: $(SDL2_CFLAGS) $(SDL2_LIBS)"

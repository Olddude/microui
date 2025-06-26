# Microui Build System

VERSION = $(shell grep -o '"version":\s*"[^"]*"' share/config/microui.config.json 2>/dev/null | grep -o '"[^"]*"$$' | tr -d '"' || echo "latest")
PREFIX ?= /usr/local
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
LDFLAGS ?= $(SDL2_LIBS) $(GLFLAG) -lm -lpthread
DEBUG_FLAGS ?= -g -DDEBUG -O0
RELEASE_FLAGS ?= -O3
TEST_FLAGS ?= -DTEST_MODE

TARGET ?= microui
LIB_TARGET ?= lib$(TARGET).a

HEADERS = \
	include/core.h \
	include/microui.h \
	include/renderer.h \
	include/client.h \
	include/server.h \
	include/window.h \
	include/console.h

SOURCES = \
	src/core.c \
	src/microui.c \
	src/renderer.c \
	src/client.c \
	src/server.c \
	src/window.c \
	src/console.c

MAIN = src/main.c

DIST_DIR ?= dist
DIST_BIN_DIR = $(DIST_DIR)/bin
DIST_LIB_DIR = $(DIST_DIR)/lib
DIST_OBJ_DIR = $(DIST_DIR)/obj
DIST_TEST_DIR = $(DIST_DIR)/test
DIST_SHARE_DIR = $(DIST_DIR)/share
DIST_INCLUDE_DIR = $(DIST_DIR)/include

ARTIFACTS_DIR = artifacts

# Logging configuration
LOGS_DIR = logs
BUILD_TIMESTAMP := $(shell date -u +"%Y-%m-%dT%H:%M:%SZ")
LOG_FILE = $(LOGS_DIR)/$(BUILD_TIMESTAMP).log

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
	uninstall \
	package \
	clean \
	clean-full \
	help \
	version \
	patch \
	minor \
	major \
	ldd \
	tree

all: $(DIST_BIN_DIR)/$(TARGET) $(DIST_LIB_DIR)/$(LIB_TARGET) headers share | $(LOGS_DIR)
	@echo "🎯 Build completed successfully at $(BUILD_TIMESTAMP)" | tee -a $(LOG_FILE)

lib: $(DIST_LIB_DIR)/$(LIB_TARGET) headers | $(LOGS_DIR)
	@echo "📚 Library build completed successfully at $(BUILD_TIMESTAMP)" | tee -a $(LOG_FILE)

debug: CFLAGS += $(DEBUG_FLAGS)
debug: $(DIST_BIN_DIR)/$(TARGET) $(DIST_LIB_DIR)/$(LIB_TARGET) headers share | $(LOGS_DIR)
	@echo "🐛 Debug build completed successfully at $(BUILD_TIMESTAMP)" | tee -a $(LOG_FILE)

release: CFLAGS += $(RELEASE_FLAGS)
release: $(DIST_BIN_DIR)/$(TARGET) $(DIST_LIB_DIR)/$(LIB_TARGET) headers share | $(LOGS_DIR)
	@echo "🚀 Release build completed successfully at $(BUILD_TIMESTAMP)" | tee -a $(LOG_FILE)

static: | $(LOGS_DIR)
	@echo "🔗 Building with static linking for $(OS_NAME)..." | tee -a $(LOG_FILE)
ifeq ($(OS_NAME),Msys)
	$(MAKE) LDFLAGS="-static -lSDL2main -lSDL2 -lopengl32 -lm -lwinmm -lole32 -loleaut32 -limm32 -lversion -luuid -ladvapi32 -lsetupapi -lshell32 -ldinput8" $(DIST_BIN_DIR)/$(TARGET) $(DIST_LIB_DIR)/$(LIB_TARGET) headers share 2>&1 | tee -a $(LOG_FILE)
else ifeq ($(OS_NAME),Darwin)
	$(MAKE) LDFLAGS="/opt/homebrew/lib/libSDL2.a /opt/homebrew/lib/libSDL2main.a -framework OpenGL -framework CoreGraphics -framework CoreServices -framework ForceFeedback -framework Cocoa -framework Carbon -framework IOKit -framework CoreAudio -framework CoreFoundation -framework CoreHaptics -framework GameController -framework Metal -framework AudioToolbox -framework AVFoundation -framework CoreVideo -framework QuartzCore -lm -liconv" $(DIST_BIN_DIR)/$(TARGET) $(DIST_LIB_DIR)/$(LIB_TARGET) headers share 2>&1 | tee -a $(LOG_FILE)
else
	$(MAKE) LDFLAGS="-static -lSDL2main -lSDL2 -lGL -lm -lpthread -ldl -lasound -lpulse -lX11 -lXext -lXcursor -lXinerama -lXi -lXrandr -lXss -lXxf86vm -lwayland-egl -lwayland-client -lwayland-cursor -lxkbcommon" $(DIST_BIN_DIR)/$(TARGET) $(DIST_LIB_DIR)/$(LIB_TARGET) headers share 2>&1 | tee -a $(LOG_FILE)
endif
	@echo "🔗 Static build completed successfully at $(BUILD_TIMESTAMP)" | tee -a $(LOG_FILE)

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

share: | $(DIST_SHARE_DIR) $(LOGS_DIR)
	@echo "⚙️  Configuring project..." | tee -a $(LOG_FILE)
	@cp -r share/* $(DIST_SHARE_DIR)/
	@echo "✅ Configuration files copied to $(DIST_SHARE_DIR)/" | tee -a $(LOG_FILE)

headers: | $(DIST_INCLUDE_DIR) $(LOGS_DIR)
	@echo "📋 Copying headers to dist/include/..." | tee -a $(LOG_FILE)
	@cp $(HEADERS) $(DIST_INCLUDE_DIR)/
	@echo "✅ Headers copied to $(DIST_INCLUDE_DIR)/" | tee -a $(LOG_FILE)

$(DIST_BIN_DIR)/$(TARGET): $(OBJ_FILES) $(MAIN_OBJ_FILE) | $(DIST_BIN_DIR) $(LOGS_DIR)
	@echo "🔗 Linking objects into executable $(TARGET)..." | tee -a $(LOG_FILE)
	@echo "   Objects: $(notdir $(OBJ_FILES)) $(notdir $(MAIN_OBJ_FILE))" | tee -a $(LOG_FILE)
	$(CC) $(OBJ_FILES) $(MAIN_OBJ_FILE) -o $@ $(LDFLAGS) 2>&1 | tee -a $(LOG_FILE)
	@echo "✅ Built executable $(TARGET) successfully" | tee -a $(LOG_FILE)

# Ensure all object files are built before creating the library
$(DIST_LIB_DIR)/$(LIB_TARGET): $(OBJ_FILES) | $(DIST_LIB_DIR) $(LOGS_DIR)
	@echo "📚 Creating static library $(LIB_TARGET)..." | tee -a $(LOG_FILE)
	@echo "   Archive: $(notdir $(OBJ_FILES))" | tee -a $(LOG_FILE)
	@ls -la $(DIST_OBJ_DIR)/ | tee -a $(LOG_FILE)
	$(AR) rcs $@ $(OBJ_FILES) 2>&1 | tee -a $(LOG_FILE)
	@echo "✅ Built static library $(LIB_TARGET) successfully" | tee -a $(LOG_FILE)

# Compile individual source files to object files
$(DIST_OBJ_DIR)/core.o: src/core.c $(HEADERS) | $(DIST_OBJ_DIR) $(LOGS_DIR)
	@echo "🔨 Compiling src/core.c → core.o" | tee -a $(LOG_FILE)
	$(CC) $(CFLAGS) -c src/core.c -o $@ 2>&1 | tee -a $(LOG_FILE)

$(DIST_OBJ_DIR)/microui.o: src/microui.c $(HEADERS) | $(DIST_OBJ_DIR) $(LOGS_DIR)
	@echo "🔨 Compiling src/microui.c → microui.o" | tee -a $(LOG_FILE)
	$(CC) $(CFLAGS) -c src/microui.c -o $@ 2>&1 | tee -a $(LOG_FILE)

$(DIST_OBJ_DIR)/renderer.o: src/renderer.c $(HEADERS) | $(DIST_OBJ_DIR) $(LOGS_DIR)
	@echo "🔨 Compiling src/renderer.c → renderer.o" | tee -a $(LOG_FILE)
	$(CC) $(CFLAGS) -c src/renderer.c -o $@ 2>&1 | tee -a $(LOG_FILE)

$(DIST_OBJ_DIR)/client.o: src/client.c $(HEADERS) | $(DIST_OBJ_DIR) $(LOGS_DIR)
	@echo "🔨 Compiling src/client.c → client.o" | tee -a $(LOG_FILE)
	$(CC) $(CFLAGS) -c src/client.c -o $@ 2>&1 | tee -a $(LOG_FILE)

$(DIST_OBJ_DIR)/server.o: src/server.c $(HEADERS) | $(DIST_OBJ_DIR) $(LOGS_DIR)
	@echo "🔨 Compiling src/server.c → server.o" | tee -a $(LOG_FILE)
	$(CC) $(CFLAGS) -c src/server.c -o $@ 2>&1 | tee -a $(LOG_FILE)

$(DIST_OBJ_DIR)/window.o: src/window.c $(HEADERS) | $(DIST_OBJ_DIR) $(LOGS_DIR)
	@echo "🔨 Compiling src/window.c → window.o" | tee -a $(LOG_FILE)
	$(CC) $(CFLAGS) -c src/window.c -o $@ 2>&1 | tee -a $(LOG_FILE)

$(DIST_OBJ_DIR)/console.o: src/console.c $(HEADERS) | $(DIST_OBJ_DIR) $(LOGS_DIR)
	@echo "🔨 Compiling src/console.c → console.o" | tee -a $(LOG_FILE)
	$(CC) $(CFLAGS) -c src/console.c -o $@ 2>&1 | tee -a $(LOG_FILE)

$(DIST_OBJ_DIR)/main.o: src/main.c $(HEADERS) | $(DIST_OBJ_DIR) $(LOGS_DIR)
	@echo "🔨 Compiling src/main.c → main.o" | tee -a $(LOG_FILE)
	$(CC) $(CFLAGS) -c src/main.c -o $@ 2>&1 | tee -a $(LOG_FILE)

test-unit: $(DIST_TEST_DIR)/unit_tests share | $(LOGS_DIR)
	@echo "🧪 Running unit tests..." | tee -a $(LOG_FILE)
	@$(DIST_TEST_DIR)/unit_tests 2>&1 | tee -a $(LOG_FILE)

test-integration: $(DIST_TEST_DIR)/integration_tests share | $(LOGS_DIR)
	@echo "🔬 Running integration tests..." | tee -a $(LOG_FILE)
	@$(DIST_TEST_DIR)/integration_tests 2>&1 | tee -a $(LOG_FILE)

test-performance: $(DIST_TEST_DIR)/performance_tests share | $(LOGS_DIR)
	@echo "⚡ Running performance tests..." | tee -a $(LOG_FILE)
	@$(DIST_TEST_DIR)/performance_tests 2>&1 | tee -a $(LOG_FILE)

$(DIST_TEST_DIR)/unit_tests: tests/unit_tests.c $(HEADERS) | $(DIST_TEST_DIR) $(LOGS_DIR)
	@echo "🔨 Building unit tests..." | tee -a $(LOG_FILE)
	$(CC) $(CFLAGS) $(TEST_FLAGS) tests/unit_tests.c -o $@ $(LDFLAGS) 2>&1 | tee -a $(LOG_FILE)

$(DIST_TEST_DIR)/integration_tests: tests/integration_tests.c $(HEADERS) $(DIST_OBJ_DIR)/core.o | $(DIST_TEST_DIR) $(LOGS_DIR)
	@echo "🔨 Building integration tests..." | tee -a $(LOG_FILE)
	$(CC) $(CFLAGS) $(TEST_FLAGS) tests/integration_tests.c $(DIST_OBJ_DIR)/core.o -o $@ $(LDFLAGS) 2>&1 | tee -a $(LOG_FILE)

$(DIST_TEST_DIR)/performance_tests: tests/performance_tests.c $(HEADERS) | $(DIST_TEST_DIR) $(LOGS_DIR)
	@echo "🔨 Building performance tests..." | tee -a $(LOG_FILE)
	$(CC) $(CFLAGS) $(TEST_FLAGS) tests/performance_tests.c -o $@ $(LDFLAGS) 2>&1 | tee -a $(LOG_FILE)

check: $(SOURCES) $(HEADERS) | $(LOGS_DIR)
	@echo "🔍 Running static analysis..." | tee -a $(LOG_FILE)
	@cppcheck --std=c11 src/ include/ tests/ 2>&1 | tee -a $(LOG_FILE)

lint: $(SOURCES) $(HEADERS) | $(LOGS_DIR)
	@echo "🔍 Checking code style..." | tee -a $(LOG_FILE)
	@clang-format --dry-run --Werror src/*.c include/*.h tests/*.c 2>&1 | tee -a $(LOG_FILE)

ldd: $(DIST_BIN_DIR)/$(TARGET)
	@echo "🔍 Checking executable dependencies..."
ifeq ($(OS_NAME),Darwin)
	@otool -L $(DIST_BIN_DIR)/$(TARGET)
else ifeq ($(OS_NAME),Msys)
	@objdump -p $(DIST_BIN_DIR)/$(TARGET) | grep "DLL Name"
else
	@ldd $(DIST_BIN_DIR)/$(TARGET)
endif

tree: | $(DIST_DIR)
	@echo "🌳 Distribution directory structure:"
	@tree ./dist -L 7 2>/dev/null || (echo "📂 tree command not available, using ls -la:" && find ./dist -type d | head -20)

$(DIST_BIN_DIR):
	@echo "📁 Creating directory $(DIST_BIN_DIR)"
	@mkdir -p $(DIST_BIN_DIR)

$(DIST_LIB_DIR):
	@echo "📁 Creating directory $(DIST_LIB_DIR)"
	@mkdir -p $(DIST_LIB_DIR)

$(DIST_OBJ_DIR):
	@echo "📁 Creating directory $(DIST_OBJ_DIR)"
	@mkdir -p $(DIST_OBJ_DIR)

$(DIST_TEST_DIR):
	@echo "📁 Creating directory $(DIST_TEST_DIR)"
	@mkdir -p $(DIST_TEST_DIR)

$(DIST_SHARE_DIR):
	@echo "📁 Creating directory $(DIST_SHARE_DIR)"
	@mkdir -p $(DIST_SHARE_DIR)

$(DIST_INCLUDE_DIR):
	@echo "📁 Creating directory $(DIST_INCLUDE_DIR)"
	@mkdir -p $(DIST_INCLUDE_DIR)

$(LOGS_DIR):
	@echo "📁 Creating directory $(LOGS_DIR)"
	@mkdir -p $(LOGS_DIR)

package: $(DIST_BIN_DIR)/$(TARGET) $(DIST_LIB_DIR)/$(LIB_TARGET) headers share | $(ARTIFACTS_DIR) $(LOGS_DIR)
	@echo "📦 Creating package..." | tee -a $(LOG_FILE)
	@echo "📋 Creating archive..." | tee -a $(LOG_FILE)
	@cd $(DIST_DIR) && tar -czf ../$(ARTIFACTS_DIR)/$(TARGET)-$(VERSION).tar.gz bin/ lib/ include/ share/
	@echo "✅ Package created: $(ARTIFACTS_DIR)/$(TARGET)-$(VERSION).tar.gz" | tee -a $(LOG_FILE)

$(ARTIFACTS_DIR):
	@mkdir -p $(ARTIFACTS_DIR)

install: $(DIST_BIN_DIR)/$(TARGET) $(DIST_LIB_DIR)/$(LIB_TARGET) headers share
	@echo "📥 Installing to $(PREFIX)..."
	@install -d $(DESTDIR)$(BIN_DIR)
	@install -d $(DESTDIR)$(LIB_DIR)
	@install -d $(DESTDIR)$(INCLUDE_DIR)
	@install -d $(DESTDIR)$(SHARE_DIR)
	@install -d $(DESTDIR)$(LOG_DIR)
	@install -m 755 $(DIST_BIN_DIR)/$(TARGET) $(DESTDIR)$(BIN_DIR)/
	@install -m 644 $(DIST_LIB_DIR)/$(LIB_TARGET) $(DESTDIR)$(LIB_DIR)/
	@install -m 644 $(HEADERS) $(DESTDIR)$(INCLUDE_DIR)/
	@cp -r $(DIST_SHARE_DIR)/* $(DESTDIR)$(SHARE_DIR)/
	@echo "✅ Installation completed!"
	@echo "📁 Binary: $(BIN_DIR)/$(TARGET)"
	@echo "📁 Library: $(LIB_DIR)/$(LIB_TARGET)"
	@echo "📁 Headers: $(INCLUDE_DIR)/"
	@echo "📁 Config: $(SHARE_DIR)/"
	@echo "📁 Logs: $(LOG_DIR)/"

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
	@current_version=$$(grep -o '"version":\s*"[^"]*"' share/config/microui.config.json | grep -o '"[^"]*"$$' | tr -d '"'); \
	major=$$(echo $$current_version | cut -d. -f1); \
	minor=$$(echo $$current_version | cut -d. -f2); \
	patch=$$(echo $$current_version | cut -d. -f3); \
	new_patch=$$((patch + 1)); \
	new_version="$$major.$$minor.$$new_patch"; \
	sed -i.bak "s/\"version\":\s*\"[^\"]*\"/\"version\": \"$$new_version\"/" share/config/microui.config.json && rm share/config/microui.config.json.bak; \
	echo "✅ Version bumped from $$current_version to $$new_version"

minor:
	@echo "🔧 Bumping minor version..."
	@current_version=$$(grep -o '"version":\s*"[^"]*"' share/config/microui.config.json | grep -o '"[^"]*"$$' | tr -d '"'); \
	major=$$(echo $$current_version | cut -d. -f1); \
	minor=$$(echo $$current_version | cut -d. -f2); \
	new_minor=$$((minor + 1)); \
	new_version="$$major.$$new_minor.0"; \
	sed -i.bak "s/\"version\":\s*\"[^\"]*\"/\"version\": \"$$new_version\"/" share/config/microui.config.json && rm share/config/microui.config.json.bak; \
	echo "✅ Version bumped from $$current_version to $$new_version"

major:
	@echo "🔧 Bumping major version..."
	@current_version=$$(grep -o '"version":\s*"[^"]*"' share/config/microui.config.json | grep -o '"[^"]*"$$' | tr -d '"'); \
	major=$$(echo $$current_version | cut -d. -f1); \
	new_major=$$((major + 1)); \
	new_version="$$new_major.0.0"; \
	sed -i.bak "s/\"version\":\s*\"[^\"]*\"/\"version\": \"$$new_version\"/" share/config/microui.config.json && rm share/config/microui.config.json.bak; \
	echo "✅ Version bumped from $$current_version to $$new_version"

clean:
	@echo "🧹 Cleaning build artifacts..."
	@rm -rf $(DIST_DIR)
	@echo "✅ Cleanup completed!"

clean-full:
	@echo "🧹 Cleaning all artifacts and environment files..."
	@rm -rf $(DIST_DIR)
	@rm -rf $(ARTIFACTS_DIR)
	@rm -rf $(LOGS_DIR)
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
	@echo "  tree             - Show distribution directory structure"
	@echo "  test-unit        - Run unit tests"
	@echo "  test-integration - Run integration tests"
	@echo "  test-performance - Run performance tests"
	@echo "  install          - Install binary, library, headers, and config files to system (use PREFIX=path to customize)"
	@echo "  package          - Create a distributable tar.gz package"
	@echo "  uninstall        - Remove from system"
	@echo "  clean            - Remove build artifacts (keeps artifacts/, logs/ and .env files)"
	@echo "  clean-full       - Remove all artifacts including artifacts/, logs/ and .env files"
	@echo "  version          - Display current version"
	@echo "  patch            - Bump patch version (x.y.z -> x.y.z+1)"
	@echo "  minor            - Bump minor version (x.y.z -> x.y+1.0)"
	@echo "  major            - Bump major version (x.y.z -> x+1.0.0)"
	@echo "  help             - Show this help"
	@echo ""
	@echo "📝 Build logs are written to: ./logs/<iso-datetime-utc>.log"
	@echo "🖥️  Detected OS: $(OS_NAME)"
	@echo "🔗 OpenGL flags: $(GLFLAG)"
	@echo "📦 SDL2 flags: $(SDL2_CFLAGS) $(SDL2_LIBS)"

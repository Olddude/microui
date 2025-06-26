# Microui Build System

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
	include/renderer.h

SOURCES = \
	src/renderer.c \
	src/microui.c

MAIN = src/main.c

DIST_DIR ?= dist
DIST_BIN_DIR = $(DIST_DIR)/bin
DIST_LIB_DIR = $(DIST_DIR)/lib
DIST_OBJ_DIR = $(DIST_DIR)/obj
DIST_TEST_DIR = $(DIST_DIR)/test
DIST_CONF_DIR = $(DIST_DIR)/config
DIST_INCLUDE_DIR = $(DIST_DIR)/include

BIN_DIR = $(PREFIX)/bin
INCLUDE_DIR = $(PREFIX)/include/$(TARGET)
LIB_DIR = $(PREFIX)/lib/$(TARGET)
CONF_DIR = $(PREFIX)/etc/$(TARGET)
LOG_DIR = $(PREFIX)/var/log/$(TARGET)
SHARE_DIR = $(PREFIX)/share/$(TARGET)

OBJECTS = $(SOURCES:.c=.o)
MAIN_OBJ = $(MAIN:.c=.o)
OBJ_FILES = $(addprefix $(DIST_OBJ_DIR)/, $(notdir $(OBJECTS)))
MAIN_OBJ_FILE = $(addprefix $(DIST_OBJ_DIR)/, $(notdir $(MAIN_OBJ)))

TEST_SOURCES = tests/integration_tests.c tests/unit_tests.c tests/performance_tests.c
TEST_TARGETS = $(DIST_TEST_DIR)/integration_tests $(DIST_TEST_DIR)/unit_tests $(DIST_TEST_DIR)/performance_tests
TEST_LIBS = ""

CONF_FILES = microui.conf

.PHONY: \
	all \
	lib \
	debug \
	release \
	deps \
	dependencies \
	dev-dependencies \
	config \
	headers \
	check \
	lint \
	test-unit \
	test-integration \
	test-performance \
	install \
	install-lib \
	uninstall \
	clean \
	help \
	version \
	patch \
	minor \
	major

all: $(DIST_BIN_DIR)/$(TARGET) $(DIST_LIB_DIR)/$(LIB_TARGET) headers config

lib: $(DIST_LIB_DIR)/$(LIB_TARGET) headers

debug: CFLAGS += $(DEBUG_FLAGS)
debug: $(DIST_BIN_DIR)/$(TARGET) $(DIST_LIB_DIR)/$(LIB_TARGET) headers config

release: CFLAGS += $(RELEASE_FLAGS)
release: $(DIST_BIN_DIR)/$(TARGET) $(DIST_LIB_DIR)/$(LIB_TARGET) headers config

deps: dependencies

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

config: | $(DIST_CONF_DIR)
	@echo "⚙️  Configuring project..."
	@cp config/*.conf $(DIST_CONF_DIR)/
	@echo "✅ Configuration files copied to $(DIST_CONF_DIR)/"

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

test-unit: $(DIST_TEST_DIR)/unit_tests config
	@echo "🧪 Running unit tests..."
	@mkdir -p $(DIST_TEST_DIR)
	@cd $(DIST_TEST_DIR) && ./unit_tests

test-integration: $(DIST_TEST_DIR)/integration_tests config
	@echo "🔬 Running integration tests..."
	@mkdir -p $(DIST_TEST_DIR)
	@cd $(DIST_TEST_DIR) && ./integration_tests

test-performance: $(DIST_TEST_DIR)/performance_tests config
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

$(DIST_BIN_DIR):
	@mkdir -p $(DIST_BIN_DIR)

$(DIST_LIB_DIR):
	@mkdir -p $(DIST_LIB_DIR)

$(DIST_OBJ_DIR):
	@mkdir -p $(DIST_OBJ_DIR)

$(DIST_TEST_DIR):
	@mkdir -p $(DIST_TEST_DIR)

$(DIST_CONF_DIR):
	@mkdir -p $(DIST_CONF_DIR)

$(DIST_INCLUDE_DIR):
	@mkdir -p $(DIST_INCLUDE_DIR)

install: $(DIST_BIN_DIR)/$(TARGET) $(DIST_LIB_DIR)/$(LIB_TARGET)
	@echo "📥 Installing to $(PREFIX)..."
	@install -d $(DESTDIR)$(BIN_DIR)
	@install -d $(DESTDIR)$(LIB_DIR)
	@install -d $(DESTDIR)$(INCLUDE_DIR)
	@install -d $(DESTDIR)$(CONF_DIR)
	@install -d $(DESTDIR)$(LOG_DIR)
	@install -m 755 $(DIST_BIN_DIR)/$(TARGET) $(DESTDIR)$(BIN_DIR)/
	@install -m 644 $(DIST_LIB_DIR)/$(LIB_TARGET) $(DESTDIR)$(LIB_DIR)/
	@install -m 644 $(HEADERS) $(DESTDIR)$(INCLUDE_DIR)/
	@install -m 644 config/*.conf $(DESTDIR)$(CONF_DIR)/
	@echo "✅ Installation completed!"
	@echo "📁 Binary: $(BIN_DIR)/$(TARGET)"
	@echo "📁 Library: $(LIB_DIR)/$(LIB_TARGET)"
	@echo "📁 Headers: $(INCLUDE_DIR)/"
	@echo "📁 Config: $(CONF_DIR)/"
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
	@rm -rf $(DESTDIR)$(CONF_DIR)
	@echo "✅ Uninstallation completed!"

# Version management targets
version:
	@echo "$(shell cat .version)"

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
	@echo "✅ Cleanup completed!"

help:
	@echo "🚀 Microui Build System"
	@echo ""
	@echo "📋 Available targets:"
	@echo "  all              - Build the main binary and static library"
	@echo "  lib              - Build only the static library (without main.c)"
	@echo "  debug            - Build with debug symbols"
	@echo "  release          - Build with release optimizations"
	@echo "  deps/dependencies- Install system dependencies (SDL2)"
	@echo "  dev-dependencies - Install development tools (build-essential, clang-format, cppcheck)"
	@echo "  config           - Copy configuration files to dist directory"
	@echo "  headers          - Copy header files to dist directory"
	@echo "  check            - Run static analysis"
	@echo "  lint             - Run code style checker"
	@echo "  test-unit        - Run unit tests"
	@echo "  test-integration - Run integration tests"
	@echo "  test-performance - Run performance tests"
	@echo "  install          - Install binary and library to system (use PREFIX=path to customize)"
	@echo "  install-lib      - Install only library and headers to system"
	@echo "  uninstall        - Remove from system"
	@echo "  clean            - Remove all build artifacts"
	@echo "  version          - Display current version"
	@echo "  patch            - Bump patch version (x.y.z -> x.y.z+1)"
	@echo "  minor            - Bump minor version (x.y.z -> x.y+1.0)"
	@echo "  major            - Bump major version (x.y.z -> x+1.0.0)"
	@echo "  help             - Show this help"
	@echo ""
	@echo "🖥️  Detected OS: $(OS_NAME)"
	@echo "🔗 OpenGL flags: $(GLFLAG)"
	@echo "📦 SDL2 flags: $(SDL2_CFLAGS) $(SDL2_LIBS)"

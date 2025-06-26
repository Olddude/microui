#!/bin/bash
# shellcheck disable=SC1091
set -e

script_file_path="${BASH_SOURCE[0]}"
script_dir_path="$(cd "$(dirname "$script_file_path")" && pwd)"
root_dir_path="$(cd "$script_dir_path/.." && pwd)"

if [ "$(pwd)" != "$root_dir_path" ]; then
    cd "$root_dir_path"
fi

if [ -f .env ]; then
    set -a
    source .env
    set +a
fi

# OS Detection
OS_NAME=$(uname -o 2>/dev/null || uname -s)

echo "🔧 Installing dependencies for $OS_NAME..."

case "$OS_NAME" in
"Msys")
    echo "📦 Please install SDL2 for Windows manually"
    echo "   Download from: https://www.libsdl.org/download-2.0.php"
    echo "   Extract to a directory and set SDL2_DIR environment variable"
    ;;
"Darwin")
    echo "🍺 Installing SDL2 via Homebrew..."
    if ! command -v brew &>/dev/null; then
        echo "❌ Homebrew not found. Please install it first."
        echo "   Visit: https://brew.sh/"
        exit 1
    fi
    brew install sdl2
    echo "✅ SDL2 installed successfully"
    ;;
"GNU/Linux" | "Linux")
    echo "🐧 Installing SDL2 for Linux..."
    # Detect package manager
    if command -v apt-get &>/dev/null; then
        apt-get update -y
        apt-get install libsdl2-dev -y
    elif command -v yum &>/dev/null; then
        yum install SDL2-devel -y
    elif command -v dnf &>/dev/null; then
        dnf install SDL2-devel -y
    elif command -v pacman &>/dev/null; then
        pacman -S sdl2 --noconfirm
    else
        echo "❌ Unsupported package manager. Please install SDL2 development libraries manually."
        exit 1
    fi
    echo "✅ SDL2 development libraries installed successfully"
    ;;
*)
    echo "❌ Unsupported operating system: $OS_NAME"
    echo "   Please install SDL2 development libraries manually."
    exit 1
    ;;
esac

echo "🎉 Dependencies installation completed!"

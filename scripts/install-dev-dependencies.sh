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

echo "🛠️  Installing development dependencies for $OS_NAME..."

case "$OS_NAME" in
"Msys")
    echo "📦 Please install development tools for Windows manually:"
    echo "   - Visual Studio Build Tools or MinGW-w64"
    echo "   - clang-format (via LLVM installer)"
    echo "   - cppcheck (download from http://cppcheck.sourceforge.net/)"
    echo "   - Git for Windows (if not already installed)"
    echo ""
    echo "💡 Alternative: Use MSYS2 package manager:"
    echo "   pacman -S mingw-w64-x86_64-toolchain"
    echo "   pacman -S mingw-w64-x86_64-clang-tools-extra"
    echo "   pacman -S mingw-w64-x86_64-cppcheck"
    ;;
"Darwin")
    echo "🍺 Installing development tools via Homebrew..."
    if ! command -v brew &>/dev/null; then
        echo "❌ Homebrew not found. Please install it first."
        echo "   Visit: https://brew.sh/"
        exit 1
    fi

    # Check if Xcode Command Line Tools are installed
    if ! xcode-select -p &>/dev/null; then
        echo "📱 Installing Xcode Command Line Tools..."
        xcode-select --install
        echo "⏳ Please complete the Xcode Command Line Tools installation and run this script again."
        exit 1
    fi

    brew install clang-format cppcheck
    echo "✅ Development tools installed successfully"
    echo "   Note: Xcode Command Line Tools provide build-essential equivalent"
    ;;
"GNU/Linux" | "Linux")
    echo "🐧 Installing development tools for Linux..."
    # Detect package manager
    if command -v apt-get &>/dev/null; then
        apt-get update -y
        apt-get install -y build-essential clang-format cppcheck git
    elif command -v yum &>/dev/null; then
        yum groupinstall -y "Development Tools"
        yum install -y clang-tools-extra cppcheck git
    elif command -v dnf &>/dev/null; then
        dnf groupinstall -y "Development Tools"
        dnf install -y clang-tools-extra cppcheck git
    elif command -v pacman &>/dev/null; then
        pacman -S base-devel clang cppcheck git --noconfirm
    else
        echo "❌ Unsupported package manager. Please install development tools manually:"
        echo "   - GCC or Clang compiler"
        echo "   - Make"
        echo "   - clang-format"
        echo "   - cppcheck"
        echo "   - Git"
        exit 1
    fi
    echo "✅ Development tools installed successfully"
    ;;
*)
    echo "❌ Unsupported operating system: $OS_NAME"
    echo "   Please install development tools manually:"
    echo "   - C compiler (GCC or Clang)"
    echo "   - Make"
    echo "   - clang-format"
    echo "   - cppcheck"
    echo "   - Git"
    exit 1
    ;;
esac

echo "🎉 Development dependencies installation completed!"

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

schema_path="$root_dir_path/share/schema/microui-config.schema.json"

# Colors for output
red='\033[0;31m'
green='\033[0;32m'
blue='\033[0;34m'
yellow='\033[1;33m'
nocolor='\033[0m' # No Color

print_usage() {
    echo "Usage: validate_yaml.sh <config_file> [config_file2] ..."
    echo ""
    echo "Examples:"
    echo "  validate_yaml.sh share/config/microui.config.yaml"
    echo "  validate_yaml.sh share/config/*.yaml"
}

validate_yaml_file() {
    local config_file="$1"

    echo -e "${blue}🔍 Validating: $config_file${nocolor}"

    # Check if file exists
    if [[ ! -f "$config_file" ]]; then
        echo -e "${red}❌ File not found: $config_file${nocolor}"
        return 1
    fi # Check if file is valid YAML
    if ! yq '.' "$config_file" >/dev/null 2>&1; then
        echo -e "${red}❌ Invalid YAML in: $config_file${nocolor}"
        return 1
    fi

    # Extract version
    local version=$(yq -r '.version // "missing"' "$config_file")
    if [[ "$version" == "missing" || "$version" == "null" ]]; then
        echo -e "${red}❌ Missing required field 'version' in: $config_file${nocolor}"
        return 1
    fi

    # Check version format (semantic versioning)
    if ! echo "$version" | grep -qE '^[0-9]+\.[0-9]+\.[0-9]+(-[a-zA-Z0-9.-]+)?$'; then
        echo -e "${red}❌ Invalid version format '$version' in: $config_file${nocolor}"
        return 1
    fi

    # Check client mode if present
    local client_mode=$(yq -r '.client.mode // "missing"' "$config_file")
    if [[ "$client_mode" != "missing" && "$client_mode" != "null" ]]; then
        if [[ ! "$client_mode" =~ ^(window|fullscreen|headless|console)$ ]]; then
            echo -e "${red}❌ Invalid client mode '$client_mode' in: $config_file${nocolor}"
            return 1
        fi
    fi

    # Check server mode if present
    local server_mode=$(yq -r '.server.mode // "missing"' "$config_file")
    if [[ "$server_mode" != "missing" && "$server_mode" != "null" ]]; then
        if [[ ! "$server_mode" =~ ^(console|daemon|service|embedded)$ ]]; then
            echo -e "${red}❌ Invalid server mode '$server_mode' in: $config_file${nocolor}"
            return 1
        fi
    fi

    # Success output
    echo -e "${green}✅ Valid YAML configuration${nocolor}"
    echo -e "   Version: ${yellow}$version${nocolor}"
    [[ "$client_mode" != "missing" && "$client_mode" != "null" ]] && echo -e "   Client mode: ${yellow}$client_mode${nocolor}"
    [[ "$server_mode" != "missing" && "$server_mode" != "null" ]] && echo -e "   Server mode: ${yellow}$server_mode${nocolor}"

    return 0
}

main() {
    if [[ $# -lt 1 ]]; then
        print_usage
        exit 1
    fi

    # Check if yq is available
    if ! command -v yq &>/dev/null; then
        echo -e "${red}❌ yq is required but not installed. Install with: brew install yq${nocolor}"
        exit 1
    fi

    # Check if schema exists
    if [[ ! -f "$schema_path" ]]; then
        echo -e "${red}❌ Schema file not found: $schema_path${nocolor}"
        exit 1
    fi

    echo -e "${blue}🔍 YAML Configuration Validator${nocolor}"
    echo "========================================"
    echo -e "Schema: ${yellow}$schema_path${nocolor}"
    echo ""

    local all_valid=true

    for config_file in "$@"; do
        if ! validate_yaml_file "$config_file"; then
            all_valid=false
        fi
        echo ""
    done

    if [[ "$all_valid" == true ]]; then
        echo -e "${green}🎉 All YAML configurations are valid!${nocolor}"
        exit 0
    else
        echo -e "${red}💥 Some YAML configurations failed validation${nocolor}"
        exit 1
    fi
}

main "$@"

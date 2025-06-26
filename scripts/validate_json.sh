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

SCHEMA_PATH="$root_dir_path/share/microui-config.schema.json"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

print_usage() {
    echo "Usage: validate_json.sh <config_file> [config_file2] ..."
    echo ""
    echo "Examples:"
    echo "  validate_json.sh share/microui.config.json"
    echo "  validate_json.sh share/*.json"
}

validate_json_file() {
    local config_file="$1"

    echo -e "${BLUE}🔍 Validating: $config_file${NC}"

    # Check if file exists
    if [[ ! -f "$config_file" ]]; then
        echo -e "${RED}❌ File not found: $config_file${NC}"
        return 1
    fi

    # Check if file is valid JSON
    if ! jq empty "$config_file" 2>/dev/null; then
        echo -e "${RED}❌ Invalid JSON in: $config_file${NC}"
        return 1
    fi

    # Extract version
    local version=$(jq -r '.version // "missing"' "$config_file")
    if [[ "$version" == "missing" || "$version" == "null" ]]; then
        echo -e "${RED}❌ Missing required field 'version' in: $config_file${NC}"
        return 1
    fi

    # Check version format (semantic versioning)
    if ! echo "$version" | grep -qE '^[0-9]+\.[0-9]+\.[0-9]+(-[a-zA-Z0-9.-]+)?$'; then
        echo -e "${RED}❌ Invalid version format '$version' in: $config_file${NC}"
        return 1
    fi

    # Check client mode if present
    local client_mode=$(jq -r '.client.mode // "missing"' "$config_file")
    if [[ "$client_mode" != "missing" && "$client_mode" != "null" ]]; then
        if [[ ! "$client_mode" =~ ^(window|fullscreen|headless|console)$ ]]; then
            echo -e "${RED}❌ Invalid client mode '$client_mode' in: $config_file${NC}"
            return 1
        fi
    fi

    # Check server mode if present
    local server_mode=$(jq -r '.server.mode // "missing"' "$config_file")
    if [[ "$server_mode" != "missing" && "$server_mode" != "null" ]]; then
        if [[ ! "$server_mode" =~ ^(console|daemon|service|embedded)$ ]]; then
            echo -e "${RED}❌ Invalid server mode '$server_mode' in: $config_file${NC}"
            return 1
        fi
    fi

    # Success output
    echo -e "${GREEN}✅ Valid JSON configuration${NC}"
    echo -e "   Version: ${YELLOW}$version${NC}"
    [[ "$client_mode" != "missing" && "$client_mode" != "null" ]] && echo -e "   Client mode: ${YELLOW}$client_mode${NC}"
    [[ "$server_mode" != "missing" && "$server_mode" != "null" ]] && echo -e "   Server mode: ${YELLOW}$server_mode${NC}"

    return 0
}

main() {
    if [[ $# -lt 1 ]]; then
        print_usage
        exit 1
    fi

    # Check if jq is available
    if ! command -v jq &>/dev/null; then
        echo -e "${RED}❌ jq is required but not installed. Install with: brew install jq${NC}"
        exit 1
    fi

    # Check if schema exists
    if [[ ! -f "$SCHEMA_PATH" ]]; then
        echo -e "${RED}❌ Schema file not found: $SCHEMA_PATH${NC}"
        exit 1
    fi

    echo -e "${BLUE}🔍 JSON Configuration Validator${NC}"
    echo "========================================"
    echo -e "Schema: ${YELLOW}$SCHEMA_PATH${NC}"
    echo ""

    local all_valid=true

    for config_file in "$@"; do
        if ! validate_json_file "$config_file"; then
            all_valid=false
        fi
        echo ""
    done

    if [[ "$all_valid" == true ]]; then
        echo -e "${GREEN}🎉 All JSON configurations are valid!${NC}"
        exit 0
    else
        echo -e "${RED}💥 Some JSON configurations failed validation${NC}"
        exit 1
    fi
}

main "$@"

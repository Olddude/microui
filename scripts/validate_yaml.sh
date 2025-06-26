#!/bin/bash
#
# YAML Configuration Validator for MicroUI
#
# This script validates YAML configuration files using yq and the MicroUI schema.
#

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCHEMA_PATH="$SCRIPT_DIR/../schemas/microui-config.schema.json"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

print_usage() {
    echo "Usage: validate_yaml.sh <config_file> [config_file2] ..."
    echo ""
    echo "Examples:"
    echo "  validate_yaml.sh examples/microui.config.yaml"
    echo "  validate_yaml.sh examples/*.yaml"
}

validate_yaml_file() {
    local config_file="$1"

    echo -e "${BLUE}🔍 Validating: $config_file${NC}"

    # Check if file exists
    if [[ ! -f "$config_file" ]]; then
        echo -e "${RED}❌ File not found: $config_file${NC}"
        return 1
    fi # Check if file is valid YAML
    if ! yq '.' "$config_file" >/dev/null 2>&1; then
        echo -e "${RED}❌ Invalid YAML in: $config_file${NC}"
        return 1
    fi

    # Extract version
    local version=$(yq -r '.version // "missing"' "$config_file")
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
    local client_mode=$(yq -r '.client.mode // "missing"' "$config_file")
    if [[ "$client_mode" != "missing" && "$client_mode" != "null" ]]; then
        if [[ ! "$client_mode" =~ ^(window|fullscreen|headless|console)$ ]]; then
            echo -e "${RED}❌ Invalid client mode '$client_mode' in: $config_file${NC}"
            return 1
        fi
    fi

    # Check server mode if present
    local server_mode=$(yq -r '.server.mode // "missing"' "$config_file")
    if [[ "$server_mode" != "missing" && "$server_mode" != "null" ]]; then
        if [[ ! "$server_mode" =~ ^(console|daemon|service|embedded)$ ]]; then
            echo -e "${RED}❌ Invalid server mode '$server_mode' in: $config_file${NC}"
            return 1
        fi
    fi

    # Success output
    echo -e "${GREEN}✅ Valid YAML configuration${NC}"
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

    # Check if yq is available
    if ! command -v yq &>/dev/null; then
        echo -e "${RED}❌ yq is required but not installed. Install with: brew install yq${NC}"
        exit 1
    fi

    # Check if schema exists
    if [[ ! -f "$SCHEMA_PATH" ]]; then
        echo -e "${RED}❌ Schema file not found: $SCHEMA_PATH${NC}"
        exit 1
    fi

    echo -e "${BLUE}🔍 YAML Configuration Validator${NC}"
    echo "========================================"
    echo -e "Schema: ${YELLOW}$SCHEMA_PATH${NC}"
    echo ""

    local all_valid=true

    for config_file in "$@"; do
        if ! validate_yaml_file "$config_file"; then
            all_valid=false
        fi
        echo ""
    done

    if [[ "$all_valid" == true ]]; then
        echo -e "${GREEN}🎉 All YAML configurations are valid!${NC}"
        exit 0
    else
        echo -e "${RED}💥 Some YAML configurations failed validation${NC}"
        exit 1
    fi
}

main "$@"

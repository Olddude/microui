#!/bin/bash
#
# Combined Configuration Validator for MicroUI
#
# This script validates both JSON and YAML configuration files.
#

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

print_usage() {
    echo "Usage: validate_config.sh [options] <config_file> [config_file2] ..."
    echo ""
    echo "Options:"
    echo "  -j, --json-only    Validate only JSON files"
    echo "  -y, --yaml-only    Validate only YAML files"
    echo "  -h, --help         Show this help message"
    echo ""
    echo "Examples:"
    echo "  validate_config.sh examples/microui.config.json"
    echo "  validate_config.sh examples/*.yaml"
    echo "  validate_config.sh examples/*"
    echo "  validate_config.sh --json-only examples/*.json"
}

validate_files() {
    local json_only=false
    local yaml_only=false
    local files=()

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
        -j | --json-only)
            json_only=true
            shift
            ;;
        -y | --yaml-only)
            yaml_only=true
            shift
            ;;
        -h | --help)
            print_usage
            exit 0
            ;;
        -*)
            echo -e "${RED}❌ Unknown option: $1${NC}"
            print_usage
            exit 1
            ;;
        *)
            files+=("$1")
            shift
            ;;
        esac
    done

    if [[ ${#files[@]} -eq 0 ]]; then
        echo -e "${RED}❌ No files specified${NC}"
        print_usage
        exit 1
    fi

    echo -e "${BLUE}🔍 MicroUI Configuration Validator${NC}"
    echo "=========================================="
    echo ""

    local all_valid=true
    local json_count=0
    local yaml_count=0

    for file in "${files[@]}"; do
        # Skip files that don't exist
        if [[ ! -f "$file" ]]; then
            echo -e "${RED}❌ File not found: $file${NC}"
            all_valid=false
            continue
        fi

        # Determine file type by extension
        if [[ "$file" =~ \.(json)$ ]]; then
            if [[ "$yaml_only" == false ]]; then
                if "$SCRIPT_DIR/validate_json.sh" "$file"; then
                    ((json_count++))
                else
                    all_valid=false
                fi
            fi
        elif [[ "$file" =~ \.(yaml|yml)$ ]]; then
            if [[ "$json_only" == false ]]; then
                if "$SCRIPT_DIR/validate_yaml.sh" "$file"; then
                    ((yaml_count++))
                else
                    all_valid=false
                fi
            fi
        else
            echo -e "${YELLOW}⚠️  Skipping unknown file type: $file${NC}"
        fi
        echo ""
    done

    # Summary
    echo "=========================================="
    echo -e "Validated: ${YELLOW}$json_count JSON${NC} + ${YELLOW}$yaml_count YAML${NC} files"

    if [[ "$all_valid" == true ]]; then
        echo -e "${GREEN}🎉 All configurations are valid!${NC}"
        exit 0
    else
        echo -e "${RED}💥 Some configurations failed validation${NC}"
        exit 1
    fi
}

# Check dependencies
check_dependencies() {
    local missing=false

    if ! command -v jq &>/dev/null; then
        echo -e "${RED}❌ jq is required but not installed. Install with: brew install jq${NC}"
        missing=true
    fi

    if ! command -v yq &>/dev/null; then
        echo -e "${RED}❌ yq is required but not installed. Install with: brew install yq${NC}"
        missing=true
    fi

    if [[ "$missing" == true ]]; then
        exit 1
    fi
}

main() {
    check_dependencies
    validate_files "$@"
}

main "$@"

#!/bin/bash

# Script Name: template.sh
# Description: Template bash script for the Scripts repository
# Author: Your Name
# Version: 1.0
# Created: YYYY-MM-DD
# Last Modified: YYYY-MM-DD

# Exit on any error, undefined variables, and pipe failures
set -euo pipefail

# Global variables
readonly SCRIPT_NAME=$(basename "$0")
readonly SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

# Default values
VERBOSE=false
DRY_RUN=false
INPUT_FILE=""
OUTPUT_FILE=""

# Colors for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1" >&2
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1" >&2
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1" >&2
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

log_verbose() {
    if [[ "$VERBOSE" == "true" ]]; then
        echo -e "${BLUE}[VERBOSE]${NC} $1" >&2
    fi
}

# Usage function
show_usage() {
    cat << EOF
Usage: $SCRIPT_NAME [OPTIONS]

Template bash script with standard structure and error handling.

OPTIONS:
    -i, --input FILE        Input file path (required)
    -o, --output FILE       Output file path (optional)
    -v, --verbose           Enable verbose output
    -n, --dry-run          Show what would be done without making changes
    -h, --help             Show this help message

EXAMPLES:
    $SCRIPT_NAME --input data.txt
    $SCRIPT_NAME --input data.txt --output result.txt --verbose
    $SCRIPT_NAME --input data.txt --dry-run

EOF
}

# Cleanup function
cleanup() {
    local exit_code=$?
    log_verbose "Performing cleanup..."
    # Add cleanup logic here if needed
    exit $exit_code
}

# Set up signal handling
trap cleanup EXIT INT TERM

# Validate prerequisites
validate_prerequisites() {
    log_verbose "Validating prerequisites..."
    
    # Check for required commands
    local required_commands=("cat" "grep" "sed")
    for cmd in "${required_commands[@]}"; do
        if ! command -v "$cmd" >/dev/null 2>&1; then
            log_error "Required command not found: $cmd"
            return 1
        fi
    done
    
    # Check input file
    if [[ -n "$INPUT_FILE" && ! -f "$INPUT_FILE" ]]; then
        log_error "Input file does not exist: $INPUT_FILE"
        return 1
    fi
    
    return 0
}

# Main processing function
process_data() {
    log_info "Starting data processing..."
    
    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "DRY RUN MODE - No changes will be made"
    fi
    
    # Main processing logic goes here
    log_verbose "Processing input file: $INPUT_FILE"
    
    # Example processing (replace with actual logic)
    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "Would process: $INPUT_FILE"
        if [[ -n "$OUTPUT_FILE" ]]; then
            log_info "Would write output to: $OUTPUT_FILE"
        fi
    else {
        # Actual processing logic here
        log_info "Processing file: $INPUT_FILE"
        
        # Example: copy input to output (replace with actual logic)
        if [[ -n "$OUTPUT_FILE" ]]; then
            cp "$INPUT_FILE" "$OUTPUT_FILE"
            log_success "Output written to: $OUTPUT_FILE"
        fi
    }
    
    log_success "Data processing completed"
}

# Parse command line arguments
parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -i|--input)
                INPUT_FILE="$2"
                shift 2
                ;;
            -o|--output)
                OUTPUT_FILE="$2"
                shift 2
                ;;
            -v|--verbose)
                VERBOSE=true
                shift
                ;;
            -n|--dry-run)
                DRY_RUN=true
                shift
                ;;
            -h|--help)
                show_usage
                exit 0
                ;;
            *)
                log_error "Unknown option: $1"
                show_usage
                exit 1
                ;;
        esac
    done
    
    # Validate required arguments
    if [[ -z "$INPUT_FILE" ]]; then
        log_error "Input file is required"
        show_usage
        exit 1
    fi
}

# Main function
main() {
    log_info "Starting $SCRIPT_NAME"
    
    # Parse arguments
    parse_arguments "$@"
    
    # Validate prerequisites
    if ! validate_prerequisites; then
        log_error "Prerequisites validation failed"
        exit 1
    fi
    
    # Process data
    if ! process_data; then
        log_error "Data processing failed"
        exit 1
    fi
    
    log_success "Script completed successfully"
}

# Only run main if script is executed directly (not sourced)
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
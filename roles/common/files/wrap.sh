#!/usr/bin/env bash

set -euo pipefail
IFS=$'\t\n'


readonly SCRIPT_NAME="${0##*/}"
readonly LOG_DIR="${HOME}/.logs"
readonly LOG_RETENTION_DAYS=15

readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly NC='\033[0m'


log_error() {
    printf "${RED}[ERROR]${NC} %s\n" "$*" >&2
}

log_info() {
    printf "${GREEN}[INFO]${NC} %s\n" "$*" >&2
}

log_warn() {
    printf "${YELLOW}[WARN]${NC} %s\n" "$*" >&2
}


check_root() {
    if (( EUID == 0 )); then
        log_error "This script cannot be run as root!"
        exit 1
    fi
}



# repair bricked perms
repair_permissions() {
    log_info "Repairing permissions on log files..."

    if [[ ! -d "${LOG_DIR}" ]]; then
        log_warn "Log directory ${LOG_DIR} does not exist"
        return 0
    fi

    local files_found=false
    while IFS= read -r -d '' file; do
        files_found=true
        if ! chmod 0600 "$file"; then
            log_error "Failed to change permissions on: $file"
            return 1
        fi
    done < <(find "${LOG_DIR}" -type f -name "*.gz" -not -perm 0600 -print0 2>/dev/null)

    if [[ "$files_found" == false ]]; then
        log_info "No files found that need permission repair"
    else
        log_info "Permission repair completed successfully"
    fi
}

# purge old log files
delete_old_logs() {
    log_info "Deleting log files older than ${LOG_RETENTION_DAYS} days..."

    if [[ ! -d "${LOG_DIR}" ]]; then
        log_warn "Log directory ${LOG_DIR} does not exist"
        return 0
    fi

    local files_found=false
    local deleted_count=0

    while IFS= read -r -d '' file; do
        files_found=true
        log_info "Deleting old log file: ${file##*/}"
        if shred -uz "$file" 2>/dev/null || rm -f "$file"; then
            ((deleted_count++))
        else
            log_error "Failed to delete: $file"
            return 1
        fi
    done < <(find "${LOG_DIR}" -type f -name "*.gz" -mtime +${LOG_RETENTION_DAYS} -print0 2>/dev/null)

    if [[ "$files_found" == false ]]; then
        log_info "No old log files found to delete"
    else
        log_info "Successfully deleted ${deleted_count} old log files"
    fi
}

# Setup logging redirection
setup_logging() {
    local cmd_name="$1"
    local log_file="${LOG_DIR}/${cmd_name}_$(date +"%Y-%m-%d").gz"


    if [[ ! -d "${LOG_DIR}" ]]; then
        if ! mkdir -p "${LOG_DIR}"; then
            log_error "Failed to create log directory: ${LOG_DIR}"
            return 1
        fi
    fi


    if [[ ! -w "${LOG_DIR}" ]]; then
        log_error "Log directory is not writable: ${LOG_DIR}"
        return 1
    fi

    # setup custom fd's for logging
    exec 3>&1 4>&2
    exec 1> >(tee >(gzip >> "${log_file}"))
    exec 2> >(tee >(gzip >> "${log_file}") >&2)

    log_info "Logging to: ${log_file}"
}

# Display help message
show_help() {
    cat <<EOF
NAME
    ${SCRIPT_NAME} - Command log wrapper

SYNOPSIS
    ${SCRIPT_NAME} [OPTION]... [COMMAND [ARGS]...]

DESCRIPTION
    Wrap commands to store logs in a central location (${LOG_DIR}).
    All command output is compressed and timestamped.

OPTIONS
    -h, --help              Display this help message
    repair_permissions      Fix permissions on log files (set to 0600)
    delete_old             Delete log files older than ${LOG_RETENTION_DAYS} days

EXAMPLES
    ${SCRIPT_NAME} ls -la
    ${SCRIPT_NAME} repair_permissions
    ${SCRIPT_NAME} delete_old

LOG LOCATION
    ${LOG_DIR}

EOF
}

# sanitize command
validate_command() {
    local cmd="$1"
    if ! command -v "$cmd" &>/dev/null; then
        log_error "Command not found: $cmd"
        return 127
    fi
}

# main func
main() {
    check_root

    # Handle no arguments
    if (( $# == 0 )); then
        show_help
        exit 1
    fi

    # Parse arguments
    case "$1" in
        repair_permissions)
            repair_permissions
            exit $?
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        delete_old)
            delete_old_logs
            exit $?
            ;;
        -*)
            log_error "Unknown option: $1"
            show_help
            exit 1
            ;;
        *)
            # handle cmd
            local cmd="$1"
            validate_command "$cmd"

            setup_logging "$cmd"

            log_info "Executing: $*"
            log_info "Started at: $(date)"
            echo "----------------------------------------"


            local exit_code=0
            "$@" || exit_code=$?

            echo "----------------------------------------"
            log_info "Finished at: $(date)"
            log_info "Exit code: $exit_code"

            exit $exit_code
            ;;
    esac
}
main "$@"

#!/bin/bash
# ocws-kvstore-cli.c — Command-line interface for C-written OCWS KVStore
#
# This CLI uses the libocws-kvstore.so C library for efficient persistent storage

OCWS_DIR="${OCWS_DIR:-$HOME/.config/ocws}"
KVSTORE_FILE="$OCWS_DIR/state/kvstore.dat"
mkdir -p "$(dirname "$KVSTORE_FILE")"

# Default function implementations when library is not available
export_kv() {
    local key="$1" value="$2"
    local temp_file
    temp_file="$(mktemp)"
    
    if [[ -f "$KVSTORE_FILE" ]]; then
        grep -v "^$key=" "$KVSTORE_FILE" > "$temp_file" || true
    fi
    
    echo "$key=$value" >> "$temp_file"
    mv "$temp_file" "$KVSTORE_FILE"
}

import_kv() {
    export_kv "$1" "$2"
}

retrieve_kv() {
    local key="$1"
    if [[ -f "$KVSTORE_FILE" ]]; then
        grep -q "^$key=" "$KVSTORE_FILE" && \
            grep "^$key=" "$KVSTORE_FILE" | cut -d= -f2-
        return $?
    fi
    return 1
}

delete_kv() {
    local key="$1" tmp
    if [[ -f "$KVSTORE_FILE" ]]; then
        tmp=$(mktemp "${KVSTORE_FILE}.XXXXXX") || return 1
        grep -v "^$key=" "$KVSTORE_FILE" > "$tmp" && mv "$tmp" "$KVSTORE_FILE"
    fi
}

list_kv() {
    if [[ -f "$KVSTORE_FILE" ]]; then
        cat "$KVSTORE_FILE"
    fi
}

find_kv() {
    local pattern="$1"
    if [[ -f "$KVSTORE_FILE" ]]; then
        grep -i "$pattern" "$KVSTORE_FILE"
    fi
}

export_json() {
    if [[ -f "$KVSTORE_FILE" ]]; then
        echo "{"$(paste -sd, "$KVSTORE_FILE" | sed 's/=\"/\": \"/g; s/$/"/')"}"
    else
        echo "{}"
    fi
}

backup_kvstore() {
    local backup_file="$1"
    if [[ -f "$KVSTORE_FILE" ]]; then
        cp "$KVSTORE_FILE" "$backup_file"
        echo "KV store backed up to: $backup_file"
    fi
}

restore_kvstore() {
    local backup_file="$1"
    if [[ -f "$backup_file" ]]; then
        cp "$backup_file" "$KVSTORE_FILE"
        echo "KV store restored from: $backup_file"
    else
        echo "Backup file not found: $backup_file"
    fi
}

export_kv_commands() {
    local var_prefix="${1:-OCWS}"
    echo "# OCWS KVStore shell exports"
    echo "export OCWS_KVSTORE_FILE=\"$KVSTORE_FILE\""
    
    while IFS='=' read -r key value; do
        local safe_key="${key//[^a-zA-Z0-9_]/_}"
        echo "export ${var_prefix}_${safe_key}=\"$value\""
    done < <(cat "$KVSTORE_FILE" 2>/dev/null || echo "")
}

# Main execution
main() {
    case "${1:-help}" in
        get)
            if [[ -z "$2" ]]; then
                echo "Usage: ${0} get <key>"
                exit 1
            fi
            retrieve_kv "$2"
            ;;
        set)
            if [[ -z "$2" || -z "$3" ]]; then
                echo "Usage: ${0} set <key> <value>"
                exit 1
            fi
            export_kv "$2" "$3"
            ;;
        import)
            if [[ -z "$2" || -z "$3" ]]; then
                echo "Usage: ${0} import <key> <value>"
                exit 1
            fi
            import_kv "$2" "$3"
            ;;
        delete)
            if [[ -z "$2" ]]; then
                echo "Usage: ${0} delete <key>"
                exit 1
            fi
            delete_kv "$2"
            ;;
        list)
            list_kv
            ;;
        find)
            if [[ -z "$2" ]]; then
                echo "Usage: ${0} find <pattern>"
                exit 1
            fi
            find_kv "$2"
            ;;
        json)
            export_json
            ;;
        backup)
            if [[ -z "$2" ]]; then
                echo "Usage: ${0} backup <path>"
                exit 1
            fi
            backup_kvstore "$2"
            ;;
        restore)
            if [[ -z "$2" ]]; then
                echo "Usage: ${0} restore <path>"
                exit 1
            fi
            restore_kvstore "$2"
            ;;
        export-commands)
            export_kv_commands "$2"
            ;;
        *)
            echo ""
            echo "Usage: ${0} <command> [args]"
            echo ""
            echo "Commands:"
            echo "  get <key>          Get value for key"
            echo "  set <key> <value>  Set key-value pair"
            echo "  import <key> <value>  Set key-value pair (alias for set)"
            echo "  delete <key>       Remove a key-value pair"
            echo "  list              List all key-value pairs"
            echo "  find <pattern>     Search for keys matching pattern"
            echo "  json              Export to JSON for widgets"
            echo "  backup <path>     Backup kvstore to file"
            echo "  restore <path>    Restore kvstore from file"
            echo "  export-commands [prefix] Export shell variables"
            echo ""
            echo "State stored in: $KVSTORE_FILE"
            ;;
    esac
}

main "$@"
#!/bin/bash
# ocws-kvstore.sh — Persistent key-value store for OCWS
#
# Simple key-value storage for dotfiles advanced features
# /tmp/ocws-kvstore — key=value

OCWS_DIR="${OCWS_DIR:-$HOME/.config/ocws}"
KVSTORE_FILE="$OCWS_DIR/state/kvstore"
mkdir -p "$(dirname "$KVSTORE_FILE")"

# Export a key-value pair
export_kv() {
    local key="$1" value="$2"
    local temp_file="$(mktemp)"
    
    if [[ -f "$KVSTORE_FILE" ]]; then
        # Remove any existing entry for this key
        grep -v "^$key=" "$KVSTORE_FILE" > "$temp_file" || true
    fi
    
    # Append new entry
    echo "$key=$value" >> "$temp_file"
    mv "$temp_file" "$KVSTORE_FILE"
}

# Import a key-value pair (alias for export)
import_kv() {
    export_kv "$1" "$2"
}

# Retrieve a key-value pair
retrieve_kv() {
    local key="$1"
    if [[ -f "$KVSTORE_FILE" ]]; then
        grep -q "^$key=" "$KVSTORE_FILE" && \
            grep "^$key=" "$KVSTORE_FILE" | cut -d= -f2-
        return $?
    fi
    return 1
}

# Remove a key-value pair
delete_kv() {
    local key="$1" tmp
    if [[ -f "$KVSTORE_FILE" ]]; then
        tmp=$(mktemp "${KVSTORE_FILE}.XXXXXX") || return 1
        grep -v "^$key=" "$KVSTORE_FILE" > "$tmp" && mv "$tmp" "$KVSTORE_FILE"
    fi
}

# List all key-value pairs
list_kv() {
    if [[ -f "$KVSTORE_FILE" ]]; then
        cat "$KVSTORE_FILE"
    fi
}

# Clear all key-value pairs
flush_kv() {
    rm -f "$KVSTORE_FILE"
}

# Search for key patterns
find_kv() {
    local pattern="$1"
    if [[ -f "$KVSTORE_FILE" ]]; then
        grep -i "$pattern" "$KVSTORE_FILE"
    fi
}

# Export to JSON format for widget integration (OCWS compatibility)
export_json() {
    if [[ -f "$KVSTORE_FILE" ]]; then
        local json_pairs=""
        while IFS='=' read -r key value; do
            # Escape quotes and backslashes in value
            local escaped_value="${value//\\/\\\\}"
            escaped_value="${escaped_value//\"/\\\"}"
            json_pairs="$json_pairs, \"$key\": \"$escaped_value\""
        done < <(cat "$KVSTORE_FILE" 2>/dev/null || echo "")
        local json_output="{"${json_pairs:2}"}"
        echo "$json_output"
    else
        echo "{}"
    fi
}

# Backup current state
backup_kvstore() {
    if [[ -f "$KVSTORE_FILE" ]]; then
        local backup_dir="$OCWS_DIR/state/backups/$(date +%Y%m%d-%H%M%S)"
        mkdir -p "$backup_dir"
        cp "$KVSTORE_FILE" "$backup_dir/kvstore"
        echo "KV store backed up to: $backup_dir/kvstore"
    fi
}

# Restore from backup
restore_kvstore() {
    local backup_file="$1"
    if [[ -f "$backup_file" ]]; then
        cp "$backup_file" "$KVSTORE_FILE"
        echo "KV store restored from: $backup_file"
    else
        echo "Backup file not found: $backup_file"
    fi
}

# Merge with another kvstore file
merge_kvstore() {
    local source_file="$1"
    if [[ -f "$source_file" ]]; then
        local temp_file="$(mktemp)"
        
        # Combine: existing entries + new entries
        if [[ -f "$KVSTORE_FILE" ]]; then
            cat "$KVSTORE_FILE" > "$temp_file"
        fi
        cat "$source_file" >> "$temp_file"
        
        # Sort by key and remove duplicates (keeping first occurrence)
        sort -u "$temp_file" > "$KVSTORE_FILE"
        rm -f "$temp_file"
        echo "KV store merged from: $source_file"
    else
        echo "Source file not found: $source_file"
    fi
}

# Export shell commands for sourcing
export_commands() {
    local var_prefix="${1:-OCWS}"
    echo "# OCWS KVStore shell exports"
    echo "export OCWS_KVSTORE_FILE=\"$KVSTORE_FILE\""
    
    while IFS='=' read -r key value; do
        # Create shell variable name
        local safe_key="${key//[^a-zA-Z0-9_]/_}"
        echo "export ${var_prefix}_${safe_key}=\"$value\""
    done < <(cat "$KVSTORE_FILE" 2>/dev/null || echo "")
}

# Main execution
main() {
    case "${1:-help}" in
        export)
            export_kv "$2" "$3"
            ;;
        import)
            import_kv "$2" "$3"
            ;;
        retrieve)
            retrieve_kv "$2"
            ;;
        delete)
            delete_kv "$2"
            ;;
        list)
            list_kv
            ;;
        flush)
            flush_kv
            ;;
        find)
            find_kv "$2"
            ;;
        json)
            export_json
            ;;
        backup)
            backup_kvstore
            ;;
        restore)
            restore_kvstore "$2"
            ;;
        merge)
            merge_kvstore "$2"
            ;;
        export-commands)
            export_commands "$2"
            ;;
        *)
            echo ""
            echo "Usage: ${0} <command> [args]"
            echo ""
            echo "Commands:"
            echo "  export <key> <value>   Set a key-value pair"
            echo "  import <key> <value>   Set a key-value pair (alias for export)"
            echo "  retrieve <key>         Get value for key"
            echo "  delete <key>           Remove a key-value pair"
            echo "  list                  List all key-value pairs"
            echo "  flush                 Clear all key-value pairs"
            echo "  find <pattern>         Search for keys matching pattern"
            echo "  json                  Export to JSON for widgets"
            echo "  backup                Backup current kvstore"
            echo "  restore <file>        Restore kvstore from backup"
            echo "  merge <file>          Merge with another kvstore file"
            echo "  export-commands [prefix] Export shell variables"
            echo ""
            echo "State stored in: $KVSTORE_FILE"
            ;;
    esac
}

main "$@"
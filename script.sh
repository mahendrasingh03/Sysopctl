#!/bin/bash

VERSION="1.0.0"

# Set up logging
LOG_FILE="/var/log/sysopctl.log"
log() {
    local message="$1"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] $message" >> "$LOG_FILE"
}

# Check if script is running as root for privileged operations
check_root() {
    if [ "$EUID" -ne 0 ]; then
        echo "Error: This operation requires root privileges"
        exit 1
    fi
}

# Print help message
show_help() {
    cat << EOF
System Operations Control Tool (sysopctl) v$VERSION

Usage: sysopctl [command] [options]

Commands:
    --version               Show version information
    --help                 Show this help message

    service list           List all running services
    service start NAME     Start a service
    service stop NAME      Stop a service
    
    system load           Show system load information
    
    disk usage            Show disk usage statistics
    
    process monitor       Monitor system processes
    
    logs analyze          Analyze system logs
    
    backup PATH           Backup files from specified path

Examples:
    sysopctl service list
    sysopctl service start nginx
    sysopctl disk usage
EOF
}

# Version information
show_version() {
    echo "sysopctl version $VERSION"
}

# List running services
list_services() {
    echo "Active Services:"
    echo "---------------"
    systemctl list-units --type=service --no-pager | grep "loaded active running"
}

# Start a service
start_service() {
    local service_name="$1"
    if [ -z "$service_name" ]; then
        echo "Error: Service name required"
        exit 1
    fi
    
    check_root
    echo "Starting service: $service_name"
    if systemctl start "$service_name"; then
        log "Service $service_name started successfully"
        echo "Service started successfully"
    else
        log "Failed to start service $service_name"
        echo "Failed to start service"
        exit 1
    fi
}

# Stop a service
stop_service() {
    local service_name="$1"
    if [ -z "$service_name" ]; then
        echo "Error: Service name required"
        exit 1
    fi
    
    check_root
    echo "Stopping service: $service_name"
    if systemctl stop "$service_name"; then
        log "Service $service_name stopped successfully"
        echo "Service stopped successfully"
    else
        log "Failed to stop service $service_name"
        echo "Failed to stop service"
        exit 1
    fi
}

# Show system load
show_system_load() {
    echo "System Load Information:"
    echo "----------------------"
    uptime
    echo
    echo "CPU Usage:"
    top -bn1 | grep "Cpu(s)" | sed "s/.,[0-9]*//" | awk '{print $2}'
    echo
    echo "Memory Usage:"
    free -h
}

# Show disk usage
show_disk_usage() {
    echo "Disk Usage Statistics:"
    echo "--------------------"
    df -h
}

# Monitor processes
monitor_processes() {
    echo "Monitoring Processes (Press Ctrl+C to exit)..."
    echo "--------------------------------------------"
    while true; do
        clear
        echo "Top Processes by CPU Usage:"
        ps aux --sort=-%cpu | head -n 11
        sleep 2
    done
}

# Analyze logs
analyze_logs() {
    echo "Recent System Logs:"
    echo "-----------------"
    journalctl -n 50 --no-pager
}

# Backup files
backup_files() {
    local source_path="$1"
    if [ -z "$source_path" ]; then
        echo "Error: Source path required"
        exit 1
    fi

    if [ ! -e "$source_path" ]; then
        echo "Error: Source path does not exist"
        exit 1
    }

    local backup_dir="/tmp/backup_$(date +%Y%m%d_%H%M%S)"
    echo "Creating backup of $source_path to $backup_dir"
    
    if rsync -av --progress "$source_path" "$backup_dir"; then
        log "Backup created successfully at $backup_dir"
        echo "Backup completed successfully"
    else
        log "Backup failed for $source_path"
        echo "Backup failed"
        exit 1
    fi
}

# Main command handler
case "$1" in
    --version)
        show_version
        ;;
    --help)
        show_help
        ;;
    service)
        case "$2" in
            list)
                list_services
                ;;
            start)
                start_service "$3"
                ;;
            stop)
                stop_service "$3"
                ;;
            *)
                echo "Error: Unknown service command. Use --help for usage information."
                exit 1
                ;;
        esac
        ;;
    system)
        case "$2" in
            load)
                show_system_load
                ;;
            *)
                echo "Error: Unknown system command. Use --help for usage information."
                exit 1
                ;;
        esac
        ;;
    disk)
        case "$2" in
            usage)
                show_disk_usage
                ;;
            *)
                echo "Error: Unknown disk command. Use --help for usage information."
                exit 1
                ;;
        esac
        ;;
    process)
        case "$2" in
            monitor)
                monitor_processes
                ;;
            *)
                echo "Error: Unknown process command. Use --help for usage information."
                exit 1
                ;;
        esac
        ;;
    logs)
        case "$2" in
            analyze)
                analyze_logs
                ;;
            *)
                echo "Error: Unknown logs command. Use --help for usage information."
                exit 1
                ;;
        esac
        ;;
    backup)
        backup_files "$2"
        ;;
    *)
        echo "Error: Unknown command. Use --help for usage information."
        exit 1
        ;;
esac
#!/bin/bash

SCRIPT_NAME="system_monitor"
PID_FILE="/tmp/${SCRIPT_NAME}.pid"
LOG_DIR="./logs"
INTERVAL=600

create_log_dir() {
    if [ ! -d "$LOG_DIR" ]; then
        mkdir -p "$LOG_DIR"
    fi
}

get_current_date() {
    date +%Y-%m-%d
}

get_timestamp() {
    date +"%Y-%m-%d %H:%M:%S"
}

collect_metrics() {
    memory_info=$(free | grep Mem)
    all_memory=$(echo "$memory_info" | awk '{print $2}')
    free_memory=$(echo "$memory_info" | awk '{print $4}')
    memory_used_percent=$(echo "$memory_info" | awk '{printf "%.2f", ($3/$2)*100}')
    
    cpu_used_percent=$(top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '{printf "%.2f", 100 - $1}')
    
    disk_used_percent=$(df / | awk 'NR==2 {print $5}' | sed 's/%//')
    
    load_average_1m=$(uptime | awk -F'load average:' '{print $2}' | cut -d, -f1 | sed 's/ //g')
    
    timestamp=$(get_timestamp)
    csv_line="${timestamp};${all_memory};${free_memory};${memory_used_percent};${cpu_used_percent};${disk_used_percent};${load_average_1m}"
    
    current_date=$(get_current_date)
    csv_file="${LOG_DIR}/system_report_${current_date}.csv"
    
    if [ ! -f "$csv_file" ]; then
        echo "timestamp;all_memory;free_memory;%memory_used;%cpu_used;%disk_used;load_average_1m" > "$csv_file"
    fi
    
    echo "$csv_line" >> "$csv_file"
    echo "Метрики записаны: $csv_line"
}

monitor_loop() {
    echo "Мониторинг запущен. PID: $$"
    echo "Данные записываются в: ${LOG_DIR}/system_report_$(get_current_date).csv"
    
    while true; do
        collect_metrics
        sleep $INTERVAL
    done
}

check_if_running() {
    if [ -f "$PID_FILE" ]; then
        pid=$(cat "$PID_FILE")
        if ps -p "$pid" > /dev/null 2>&1; then
            return 0
        else
            rm -f "$PID_FILE"
            return 1
        fi
    else
        return 1
    fi
}

start_monitor() {
    if check_if_running; then
        echo "Ошибка: Мониторинг уже запущен (PID: $(cat "$PID_FILE"))"
        exit 1
    fi
    
    create_log_dir
    
    monitor_loop &
    monitor_pid=$!
    
    echo $monitor_pid > "$PID_FILE"
    
    echo "Мониторинг запущен в фоне"
    echo "PID: $monitor_pid"
    echo "Логи в: $LOG_DIR"
}

stop_monitor() {
    if check_if_running; then
        pid=$(cat "$PID_FILE")
        kill "$pid"
        rm -f "$PID_FILE"
        echo "Мониторинг остановлен (PID: $pid)"
    else
        echo "Мониторинг не запущен"
        exit 1
    fi
}

status_monitor() {
    if check_if_running; then
        pid=$(cat "$PID_FILE")
        echo "Мониторинг запущен (PID: $pid)"
        echo "Файл лога: ${LOG_DIR}/system_report_$(get_current_date).csv"
    else
        echo "Мониторинг не запущен"
    fi
}

case "$1" in
    "START")
        start_monitor
        ;;
    "STOP")
        stop_monitor
        ;;
    "STATUS")
        status_monitor
        ;;
    *)
        echo "Использование: $0 {START|STOP|STATUS}"
        echo "  START - запуск мониторинга в фоне"
        echo "  STOP  - остановка мониторинга"
        echo "  STATUS - проверка статуса мониторинга"
        exit 1
        ;;
esac
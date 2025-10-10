#!/bin/bash

if [ $# -ne 2 ]; then
    echo "Использование: $0 <лог-файл> <ключевое-слово>"
    exit 1
fi

LOG_FILE="$1"
KEYWORD="$2"
OUTPUT_FILE="${KEYWORD}_count.txt"

if [ ! -f "$LOG_FILE" ]; then
    echo "Ошибка: Файл '$LOG_FILE' не существует"
    exit 1
fi

if [ ! -s "$LOG_FILE" ]; then
    echo "Ошибка: Файл '$LOG_FILE' пуст"
    exit 1
fi

COUNT=$(grep -c "$KEYWORD" "$LOG_FILE")

{
    echo "Лог-файл: $LOG_FILE"
    echo "Ключевое слово: $KEYWORD"
    echo "Количество вхождений: $COUNT"
    echo ""
    grep "$KEYWORD" "$LOG_FILE"
} > "$OUTPUT_FILE"

echo "Количество вхождений слова '$KEYWORD': $COUNT"
echo "Результаты сохранены в файл: $OUTPUT_FILE"
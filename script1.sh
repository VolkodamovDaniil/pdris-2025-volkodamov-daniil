#!/bin/bash

get_branch() {
    local branch=$1
    local branch_type
    
    if git show-ref --verify --quiet refs/heads/$branch 2>/dev/null; then
        branch_type="local"
        echo "$branch"
    elif git show-ref --verify --quiet refs/remotes/origin/$branch 2>/dev/null; then
        branch_type="remote"
        echo "origin/$branch"
    else
        echo "Ошибка: Ветка $branch не найдена"
        return 1
    fi
}

cleanup_and_exit() {
    cd ..
    rm -rf $TEMP_DIR
    exit $1
}


if [ $# -ne 3 ]; then
    echo "Использование: $0 <repository_url> <branch1> <branch2>"
    exit 1
fi

REPO_URL=$1
BRANCH1=$2
BRANCH2=$3
REPORT_FILE="diff_report_${BRANCH1}_vs_${BRANCH2}.txt"
TEMP_DIR="temp_repo_$$"

mkdir $TEMP_DIR
cd $TEMP_DIR

git clone --quiet $REPO_URL . 2>/dev/null

if [ $? -ne 0 ]; then
    echo "Ошибка: Не удалось клонировать репозиторий $REPO_URL"
    cleanup_and_exit 1
fi

git fetch --all

COMPARE1=$(get_branch $BRANCH1) || cleanup_and_exit 1
COMPARE2=$(get_branch $BRANCH2) || cleanup_and_exit 1

DIFF_OUTPUT=$(git diff --name-status $COMPARE1..$COMPARE2 2>/dev/null)

if [ $? -ne 0 ]; then
    echo "Ошибка: Не удалось сравнить ветки"
    cleanup_and_exit 1
fi

{
    echo "Отчёт о различиях между ветками"
    echo ""
    echo "================================"
    echo "Реопзиторий:    $REPO_URL"
    echo "Ветка 1:        $BRANCH1 ($COMPARE1)"
    echo "Ветка 2:        $BRANCH2 ($COMPARE2)"
    echo "Дата генерации: $(date '+%Y-%m-%d %H:%M:%S')"
    echo "================================"
    echo ""
    echo "СПИСОК ИЗМЕНЁННЫХ ФАЙЛОВ:"
    
    ADDED=0
    MODIFIED=0
    DELETED=0
    
    while IFS= read -r line; do
        if [ -n "$line" ]; then
            STATUS=${line:0:1}
            FILENAME=${line:2}
            echo "$STATUS       $FILENAME"
                
            case $STATUS in
                "A") ((ADDED++)) ;;
                "M") ((MODIFIED++)) ;;
                "D") ((DELETED++)) ;;
                "R") ((MODIFIED++)) ;;
                "C") ((MODIFIED++)) ;;
            esac
        fi
    done <<< "$DIFF_OUTPUT"
    
    TOTAL_FILES=$((ADDED + MODIFIED + DELETED))
    
    echo ""
    echo "СТАТИСТИКА:"
    echo "Всего изменённых файлов: $TOTAL_FILES"
    echo "Добавлено (A):    $ADDED"
    echo "Удалено (D):      $DELETED"
    echo "Изменено (M):     $MODIFIED"
    
} > ../$REPORT_FILE

echo "Отчёт сохранён в файл: $REPORT_FILE"
echo "Найдено изменений: $TOTAL_FILES"

cleanup_and_exit 0
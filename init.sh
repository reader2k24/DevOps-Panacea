#!/bin/bash

Проверка наличия директории .git и её удаление
if [ -d ".git" ]; then
    echo "Директория .git найдена, удаляю..."
    rm -rf .git
    echo "Директория .git удалена."
fi

TEMP_FILE=$(mktemp)

# Запрос ввода данных
read -p "Введите ваш GitLab аккаунт (username): " GITLAB_ACCOUNT
echo "Создание GitLab Access Token:
    https://gitlab.com/-/user_settings/personal_access_tokens -> Add new token
    Token Name: *****
    Select scopes: api"
read -sp "Введите ваш GitLab Access Token: " TOKEN
echo

# Сохранение данных в временный файл
echo "GITLAB_ACCOUNT=$GITLAB_ACCOUNT" > $TEMP_FILE
echo "TOKEN=$TOKEN" >> $TEMP_FILE

# Вывод пути к временному файлу
echo "Временный файл сохранен в $TEMP_FILE"

# Экспорт переменных для использования в других скриптах
export TEMP_FILE

# Переменные
PROJECT_NAME="DevOps-Panacea"
GITLAB_URL="https://gitlab.com/api/v4/projects"
GITLAB_API="https://gitlab.com/api/v4"

# Проверка существования проекта
response=$(curl --silent --header "Private-Token: $TOKEN" "$GITLAB_API/projects?search=$PROJECT_NAME")
project_id=$(echo $response | jq -r --arg PROJECT_NAME "$PROJECT_NAME" '.[] | select(.name == $PROJECT_NAME) | .id')

if [ -n "$project_id" ]; then
    echo "Проект '$PROJECT_NAME' уже существует, удаление..."
    delete_response=$(curl --silent --request DELETE --header "Private-Token: $TOKEN" "$GITLAB_API/projects/$project_id")

    # Ожидание завершения удаления проекта
    while true; do
        check_response=$(curl --silent --header "Private-Token: $TOKEN" "$GITLAB_API/projects/$project_id")
        if [[ $check_response == *"404 Project Not Found"* ]]; then
            echo "Проект '$PROJECT_NAME' успешно удален."
            sleep 5
            break
        else
            echo "Ожидание завершения удаления проекта..."
            sleep 5
        fi
    done
fi

# Создание репозитория на GitLab
response=$(curl --silent --request POST --header "Private-Token: $TOKEN" --data "name=$PROJECT_NAME&visibility=private" "$GITLAB_URL")

if [[ $response == *"\"id\""* ]]; then
    echo "Репозиторий '$PROJECT_NAME' успешно создан."
else
    echo "Ошибка создания репозитория: $response"
    exit 1
fi

# Инициализация и загрузка проекта в репозиторий на GitLab
git init --initial-branch=main
git remote add origin "https://gitlab.com/$GITLAB_ACCOUNT/$PROJECT_NAME.git"
git add .
git commit -m "Initial Project"
git push --set-upstream origin main

# Запуск создания кластера VM и настройка SSH доступа
cd VMware/
./init-vm.sh
./setup_ssh.sh
cd ..

# Инициализация Runner и создание Telegram Bot
cd gitlab-ci/
./init-gitlab.sh
python3 create-tg-bot.py "$TEMP_FILE"
cd ..

# Удаление временного файла по завершению
trap 'rm -f "$TEMP_FILE"' EXIT

# Ожидаем поднятия GitLab Runner на всех VM загружаем проект в репозиторий на GitLab.
echo "Ожидаем инициализации Runner (60s)" && sleep 60

# Запуск пайплайна
echo "Запуск пайплайна..."
curl --request POST --header "Private-Token: $TOKEN" --data "ref=main" "$GITLAB_API/projects/$project_id/pipeline"

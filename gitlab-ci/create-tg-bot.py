#!/usr/bin/env python3

import os
import sys
import requests

TOKEN_DIR = '../gitlab-ci/'

def load_env_from_file(filename):
    """Загружает переменные окружения из файла."""
    try:
        with open(filename, 'r') as file:
            for line in file:
                if '=' in line:
                    key, value = line.strip().split('=', 1)
                    os.environ[key] = value
    except FileNotFoundError:
        print(f"Ошибка: Файл {filename} не найден.")
    except Exception as e:
        print(f"Ошибка при загрузке переменных окружения: {e}")

def get_project_id(token, project_name):
    url = f'https://gitlab.com/api/v4/projects?search={project_name}'
    headers = {'PRIVATE-TOKEN': token}

    response = requests.get(url, headers=headers)
    if response.status_code != 200:
        print(f"Ошибка при запросе: {response.text}")
        return None

    projects = response.json()
    for project in projects:
        if project['name'] == project_name:
            return project['id']

    print(f"Проект '{project_name}' не найден.")
    return None

def get_bot_token():
    print()
    print("Чтобы создать Telegram бота и получить токен, выполните следующие шаги:")
    print("1. Откройте Telegram и найдите бота с именем 'BotFather'.")
    print("2. Нажмите на 'Start', чтобы начать диалог с BotFather.")
    print("3. Введите команду '/newbot' и следуйте инструкциям для создания нового бота.")
    print("4. После создания бота, BotFather предоставит вам токен. Этот токен нужно будет ввести в программу.")
    print("5. Найдите созданного бота в Telegram, используя его имя пользователя (username), и нажмите 'Start', чтобы активировать бота.")
    print()
    token = input("Введите токен вашего Telegram бота: ").strip()
    if not token:
        raise ValueError("Токен не может быть пустым.")

    if not os.path.exists(TOKEN_DIR):
        os.makedirs(TOKEN_DIR)

    return token

def get_chat_id(token):
    url = f'https://api.telegram.org/bot{token}/getUpdates'
    try:
        response = requests.get(url)
        response.raise_for_status()
    except requests.RequestException as e:
        print(f"Ошибка при запросе: {e}")
        return None

    data = response.json()

    if data.get("ok") and data.get("result"):
        chat_id = data['result'][0]['message']['chat']['id']
        print(f'Полученный chat_id: {chat_id}')
        return chat_id
    else:
        print("Не удалось получить chat_id. Убедитесь, что токен правильный.")
        return None

def add_variable_to_gitlab(project_id, key, value, token):
    url = f'https://gitlab.com/api/v4/projects/{project_id}/variables'
    headers = {'PRIVATE-TOKEN': token}
    data = {'key': key, 'value': value}

    try:
        response = requests.post(url, headers=headers, data=data)
        response.raise_for_status()
        if response.status_code == 201:
            print(f'Переменная {key} успешно добавлена в GitLab.')
        else:
            print(f'Не удалось добавить переменную {key} в GitLab: {response.json()}')
    except requests.RequestException as e:
        print(f"Ошибка при добавлении переменной в GitLab: {e}")

def send_message(token, chat_id, text):
    url = f'https://api.telegram.org/bot{token}/sendMessage'
    payload = {'chat_id': chat_id, 'text': text}
    try:
        response = requests.post(url, data=payload)
        response.raise_for_status()
    except requests.RequestException as e:
        print(f"Ошибка при отправке сообщения: {e}")
        return None
    return response.json()

def main():
    if len(sys.argv) != 2:
        print("Ошибка: Необходимо указать путь к временному файлу.")
        sys.exit(1)

    temp_file = sys.argv[1]

    # Загрузка переменных окружения из временного файла
    if not os.path.exists(temp_file):
        print(f"Ошибка: Временный файл не найден: {temp_file}")
        sys.exit(1)

    load_env_from_file(temp_file)

    gitlab_token = os.getenv('TOKEN')
    gitlab_account = os.getenv('GITLAB_ACCOUNT')

    # Отладочный вывод для проверки переменных
    print(f"GitLab Token: {gitlab_token}")
    print(f"GitLab Account: {gitlab_account}")

    if not gitlab_token or not gitlab_account:
        print("Не удалось загрузить GitLab токен и/или аккаунт из временного файла.")
        return

    project_name = "DevOps-Panacea"
    project_id = get_project_id(gitlab_token, project_name)

    if project_id:
        token = get_bot_token()
        chat_id = get_chat_id(token)

        if chat_id:
            # Отправка переменных в GitLab
            add_variable_to_gitlab(project_id, 'TELEGRAM_BOT_TOKEN', token, gitlab_token)
            add_variable_to_gitlab(project_id, 'TELEGRAM_CHAT_ID', str(chat_id), gitlab_token)

            # Отправка тестового сообщения
            message = "Привет! Это тестовое сообщение от бота."
            response = send_message(token, chat_id, message)
            if response:
                print("Ответ от Telegram API:", response)
            else:
                print("Не удалось отправить сообщение.")
    else:
        print("Не удалось найти проект в GitLab.")

if __name__ == "__main__":
    main()

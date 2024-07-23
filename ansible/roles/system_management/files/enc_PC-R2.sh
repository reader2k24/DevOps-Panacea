#!/bin/bash

# Путь к каталогу с бэкапами
BACKUP_DIR="/etc/backup/"

# Расширение файла бэкапа
BACKUP_EXTENSION=".tar.gz.enc"

# Получение самого позднего файла бэкапа
latest_backup=$(ls -t "$BACKUP_DIR" | grep "$BACKUP_EXTENSION" | head -n 1)

echo "Последний файл бэкапа: $latest_backup"

# Проверка наличия самого позднего файла бэкапа
if [ -z "$latest_backup" ]; then
    echo "Ошибка: Не удалось найти самый поздний файл бэкапа."
    exit 1
fi

# Расшифровка самого позднего файла бэкапа
echo "Расшифровка файла: $latest_backup"
openssl enc -d -aes-256-cbc -pbkdf2 -in "$BACKUP_DIR$latest_backup" -out "${BACKUP_DIR}${latest_backup%.enc}" 2>/dev/null
decrypt_exit_code=$?

# Проверка на успешность расшифровки
if [ $decrypt_exit_code -ne 0 ]; then
    echo "Ошибка: Не удалось расшифровать файл бэкапа $latest_backup. Возможно, неправильный пароль."
    rm "${BACKUP_DIR}${latest_backup%.enc}" # Удаление временного файла, если расшифровка не удалась
    exit 1
fi

# Успешное завершение
echo "Успешно: Файл бэкапа $latest_backup успешно расшифрован."

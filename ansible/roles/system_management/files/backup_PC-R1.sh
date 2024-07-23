#!/bin/bash

# Путь к каталогу etc на сервере PC-R1
SOURCE_DIR="/etc"

# Имя пользователя на сервере PC-R2
REMOTE_USER="root"

# Адрес сервера PC-R2
REMOTE_HOST="172.16.0.42"

# Путь к каталогу, куда будет производиться резервное копирование на сервере PC-R2
DEST_DIR="/etc/backup/"

# Порт PC-R2
PORT=2227

# Имя пользователя на сервере R2
REMOTE_USER_R2="root"

# Адрес сервера R2
REMOTE_HOST_R2="172.16.0.33"

# Порт R2
PORT_R2=2226

# Путь к каталогу, куда будет производиться резервное копирование паролей на сервере R2
DEST_DIR_R2="/etc/password_backup/"

# Проверяем существует ли каталог DEST_DIR_R2 на сервере R2, если нет, создаем его
if ! ssh -p $PORT_R2 $REMOTE_USER_R2@$REMOTE_HOST_R2 "[ -d \"$DEST_DIR_R2\" ]"; then
    ssh -p $PORT_R2 $REMOTE_USER_R2@$REMOTE_HOST_R2 "mkdir -p \"$DEST_DIR_R2\""
fi

# Проверяем существует ли каталог DEST_DIR на сервере PC-R2, если нет, создаем его
if ! ssh -p $PORT $REMOTE_USER@$REMOTE_HOST "[ -d \"$DEST_DIR\" ]"; then
    ssh -p $PORT $REMOTE_USER@$REMOTE_HOST "mkdir -p \"$DEST_DIR\""
fi

# Получение текущего дня и имени хоста
day=$(date +%A-%F)
hostname=$(hostname -s)

# Формирование имени архива
archive_file="$hostname-$day.tar.gz"

# Логирование
log_file="/var/log/backup.log"
log_message() {
    echo "$(date +"%Y-%m-%d %H:%M:%S") - $1" >> "$log_file"
}

# Проверка наличия и доступности каталогов
if [ ! -d "$SOURCE_DIR" ]; then
    log_message "Ошибка: Каталог $SOURCE_DIR не существует или недоступен."
    exit 1
fi
if [ ! -d "$DEST_DIR" ]; then
    log_message "Ошибка: Каталог $DEST_DIR не существует или недоступен."
    exit 1
fi

# Создаем временный каталог для архивации, переходим в него
temp_dir=$(mktemp -d)
cd "$temp_dir" || { log_message "Ошибка: Не удалось создать временный каталог."; exit 1; }

# Создание временного архива tar
tar czf "$archive_file" -C "$SOURCE_DIR" .

# Генерация случайного пароля
password=$(openssl rand -base64 32)

# Получение текущей даты
current_date=$(date +%F)

# Запись пароля в файл
echo "$password" > "/tmp/$current_date.txt"

# Шифрование архива с использованием pbkdf2 и сгенерированного пароля
openssl enc -aes-256-cbc -salt -pbkdf2 -pass file:"/tmp/$current_date.txt" -in "$archive_file" -out "$archive_file.enc"

# Отправка пароля на сервер R2
scp -P $PORT_R2 "/tmp/$current_date.txt" "$REMOTE_USER_R2@$REMOTE_HOST_R2:$DEST_DIR_R2/$current_date.txt"

# Проверка успешной отправки пароля
if [ $? -ne 0 ]; then
    log_message "Ошибка: Не удалось отправить пароль на сервер R2"
    exit 1
fi

# Отправка архива на сервер PC-R2
scp -P $PORT "$archive_file.enc" "$REMOTE_USER@$REMOTE_HOST:$DEST_DIR"

# Проверка успешной передачи архива
if [ $? -ne 0 ]; then
    log_message "Ошибка: Не удалось передать архив на сервер PC-R2."
    exit 1
fi

# Удаление временных файлов
rm -rf "$temp_dir" "/tmp/$current_date.txt"

# Логирование успешного завершения операции
log_message "Успешно: Зашифрованная резервная копия $archive_file передана на сервер $REMOTE_HOST."

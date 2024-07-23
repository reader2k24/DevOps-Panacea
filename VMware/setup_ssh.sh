#!/bin/bash

# Файл с IP адресами
IP_FILE="ip.txt"

# Файл с конфигурацией SSH, который нужно заменить
SSH_CONFIG_FILE="sshd_config"

# Файл с баннером, который нужно заменить
BANNER_FILE="banner_file"

# Пароль для пользователя debian и root
DEBIAN_PASSWORD="debian"
ROOT_PASSWORD="root"

# Переменная для хранения пути до SSH ключа
SSH_KEY="$HOME/.ssh/id_rsa"

# Функция для проверки и установки необходимых пакетов
check_and_install_packages() {
  local packages=("sshpass")

  for pkg in "${packages[@]}"; do
    if ! dpkg -l | grep -q "^ii  $pkg "; then
      echo "$pkg не найден. Установка..."
      sudo apt-get update
      sudo apt-get install -y "$pkg"
    else
      echo "$pkg уже установлен."
    fi
  done
}

# Проверка и установка необходимых пакетов
check_and_install_packages

# Проверка наличия файла с IP адресами
if [[ ! -f "$IP_FILE" ]]; then
  echo "Файл с IP адресами ($IP_FILE) не найден!"
  exit 1
fi

# Проверка наличия файла конфигурации SSH
if [[ ! -f "$SSH_CONFIG_FILE" ]]; then
  echo "Файл конфигурации SSH ($SSH_CONFIG_FILE) не найден!"
  exit 1
fi

# Проверка наличия файла баннера
if [[ ! -f "$BANNER_FILE" ]]; then
  echo "Файл баннера ($BANNER_FILE) не найден!"
  exit 1
fi

# Функция для настройки SSH на удаленной машине
setup_ssh_on_vm() {
  local ip="$1"

  echo "Настройка SSH на машине с IP: $ip"

  # Использование sshpass для автоматического ввода пароля
  sshpass -p "$DEBIAN_PASSWORD" ssh -o StrictHostKeyChecking=no debian@$ip <<EOF
    # Переключаемся на root и устанавливаем пароль
    sudo su -c "echo root:$ROOT_PASSWORD | chpasswd"

    # Замена SSH конфигурации
    sudo bash <<EOROOT
      cat > /etc/ssh/sshd_config <<EOCONFIG
$(cat $SSH_CONFIG_FILE)
EOCONFIG

      # Замена баннера SSH
      cat > /etc/issue.net <<EOBANNER
$(cat $BANNER_FILE)
EOBANNER

      # Перезапуск SSH сервиса
      systemctl restart ssh
EOROOT
EOF

  # Проверка существования SSH ключа на локальной машине, если нет, то создание
  if [[ ! -f "$SSH_KEY" ]]; then
    echo "SSH ключ не найден, создание нового..."
    ssh-keygen -t rsa -N "" -f "$SSH_KEY"
  fi

  # Перенос SSH ключа на удаленную машину
  sshpass -p "$ROOT_PASSWORD" ssh-copy-id -o StrictHostKeyChecking=no -i "$SSH_KEY" root@$ip
}

# Чтение IP адресов из файла и настройка SSH на каждой машине
while IFS= read -r ip; do
  setup_ssh_on_vm "$ip"
done < "$IP_FILE"

echo "Настройка SSH завершена на всех машинах."

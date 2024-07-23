#!/bin/bash

# Массивы с именами серверов
VM_NAMES=("R1" "PC-R1" "R2" "PC-R2" "R0")

# Конфигурации сетевых интерфейсов для каждого сервера
ETHERNET_CONFIGS_1=("ethernet1.connectionType = \"pvn\""
"ethernet1.addressType = \"generated\""
"ethernet1.pvnID = \"52 11 17 7b 48 68 63 4f-80 06 c7 42 e5 70 6c b3\""
"ethernet1.virtualDev = \"e1000\""
"ethernet1.present = \"TRUE\""
"ethernet1.pciSlotNumber = \"36\""
"ethernet1.generatedAddress = \"00:0c:29:88:53:8c\""
"ethernet1.generatedAddressOffset = \"10\""
"ethernet2.connectionType = \"pvn\""
"ethernet2.addressType = \"generated\""
"ethernet2.pvnID = \"52 e8 2d 1e 2e db 1e 62-98 91 ee cd 91 5b ae f6\""
"ethernet2.virtualDev = \"e1000\""
"ethernet2.present = \"TRUE\""
"ethernet2.pciSlotNumber = \"37\""
"ethernet2.generatedAddress = \"00:0c:29:88:53:96\""
"ethernet2.generatedAddressOffset = \"20\"")

ETHERNET_CONFIGS_2=("ethernet1.connectionType = \"pvn\""
"ethernet1.addressType = \"generated\""
"ethernet1.pvnID = \"52 e8 2d 1e 2e db 1e 62-98 91 ee cd 91 5b ae f6\""
"ethernet1.virtualDev = \"e1000\""
"ethernet1.present = \"TRUE\""
"ethernet1.pciSlotNumber = \"36\""
"ethernet1.generatedAddress = \"00:0c:29:e7:da:a4\""
"ethernet1.generatedAddressOffset = \"10\"")

ETHERNET_CONFIGS_3=("ethernet1.connectionType = \"pvn\""
"ethernet1.addressType = \"generated\""
"ethernet1.pvnID = \"52 77 02 6e 79 3d c2 a5-89 da 74 0e db e8 d9 9b\""
"ethernet1.virtualDev = \"e1000\""
"ethernet1.present = \"TRUE\""
"ethernet1.pciSlotNumber = \"36\""
"ethernet1.generatedAddress = \"00:0c:29:c4:a3:c6\""
"ethernet1.generatedAddressOffset = \"10\""
"ethernet2.connectionType = \"pvn\""
"ethernet2.addressType = \"generated\""
"ethernet2.pvnID = \"52 b1 2b 8b 40 ce 10 39-c1 a5 b9 2c 46 13 e2 cf\""
"ethernet2.virtualDev = \"e1000\""
"ethernet2.present = \"TRUE\""
"ethernet2.pciSlotNumber = \"37\""
"ethernet2.generatedAddress = \"00:0c:29:c4:a3:d0\""
"ethernet2.generatedAddressOffset = \"20\"")

ETHERNET_CONFIGS_4=("ethernet1.connectionType = \"pvn\""
"ethernet1.addressType = \"generated\""
"ethernet1.pvnID = \"52 b1 2b 8b 40 ce 10 39-c1 a5 b9 2c 46 13 e2 cf\""
"ethernet1.virtualDev = \"e1000\""
"ethernet1.present = \"TRUE\""
"ethernet1.pciSlotNumber = \"36\""
"ethernet1.generatedAddress = \"00:0c:29:3c:2d:f3\""
"ethernet1.generatedAddressOffset = \"10\"")

ETHERNET_CONFIGS_5=("ethernet1.connectionType = \"pvn\""
"ethernet1.addressType = \"generated\""
"ethernet1.pvnID = \"52 11 17 7b 48 68 63 4f-80 06 c7 42 e5 70 6c b3\""
"ethernet1.virtualDev = \"e1000\""
"ethernet1.present = \"TRUE\""
"ethernet1.pciSlotNumber = \"36\""
"ethernet1.generatedAddress = \"00:0c:29:ff:b7:9d\""
"ethernet1.generatedAddressOffset = \"10\""
"ethernet2.connectionType = \"pvn\""
"ethernet2.addressType = \"generated\""
"ethernet2.pvnID = \"52 77 02 6e 79 3d c2 a5-89 da 74 0e db e8 d9 9b\""
"ethernet2.virtualDev = \"e1000\""
"ethernet2.present = \"TRUE\""
"ethernet2.pciSlotNumber = \"37\""
"ethernet2.generatedAddress = \"00:0c:29:ff:b7:a7\""
"ethernet2.generatedAddressOffset = \"20\"")

# Переменные VM
SEVENZ_ARCHIVE="Debian_12.0.0_VMM.7z"
VMX_FILE="Debian_12.0.0_VMM_LinuxVMImages.COM.vmx"
NEW_MEMSIZE="1024"
NEW_NUMVCPUS="1"

# Функция для проверки существования VM
vm_exists() {
    local VMX_PATH="$1"
    if vmrun list | grep -q "$VMX_PATH"; then
        return 0
    else
        if [ -f "$VMX_PATH" ]; then
            return 0
        else
            return 1
        fi
    fi
}

# Функция для обработки одного сервера
process_server() {
    local VM_NAME="$1"
    shift
    local ETHERNET_CONFIG=("$@")
    local TEMP_DIR="$VM_NAME"
    local VMX_PATH="${TEMP_DIR}/${VMX_FILE}"

    # Проверка существования VM
    if vm_exists "$VMX_PATH"; then
        echo "[ ] Виртуальная машина ${VM_NAME} уже существует. Пропуск..."
        return 0
    fi

    # Создание временной папки для извлечения, если её еще нет
    mkdir -p "${TEMP_DIR}"

    # Проверка наличия файла перед распаковкой
    if [ ! -f "${TEMP_DIR}/${VMX_FILE}" ]; then
        # Параллельное извлечение архива .7z в TEMP_DIR
        echo "[*] Извлечение архива ${SEVENZ_ARCHIVE} в ${TEMP_DIR}..."
        7z x -mmt2 "${SEVENZ_ARCHIVE}" -o"${TEMP_DIR}"

        # Убедитесь, что архив был успешно извлечен
        if [ $? -ne 0 ]; then
            echo "[ ] Ошибка при извлечении архива ${SEVENZ_ARCHIVE}"
            exit 1
        fi
    else
        echo "Файл ${VMX_FILE} уже существует в ${TEMP_DIR}. Пропуск распаковки..."
    fi

    # Продолжение работы во временной директории
    cd "${TEMP_DIR}"

    # Проверка наличия VMDK файла
    if [ ! -f Debian_12.0.0_VMM_LinuxVMImages.COM.vmdk ]; then
        echo "[ ] Ошибка: Файл Debian_12.0.0_VMM_LinuxVMImages.COM.vmdk не найден в директории ${TEMP_DIR}"
        exit 1
    fi

    # Проверяем, что файл .vmx существует
    if [ ! -f "${VMX_FILE}" ]; then
        echo "[ ] Ошибка: Файл ${VMX_FILE} не найден."
        exit 1
    fi

    # Используем sed для замены или добавления параметров в .vmx файл
    # Сначала обновляем memSize
    sed -i.bak "s/^memsize = .*/memsize = \"${NEW_MEMSIZE}\"/" "${VMX_FILE}"

    # Затем обновляем numvcpus
    sed -i.bak "s/^numvcpus = .*/numvcpus = \"${NEW_NUMVCPUS}\"/" "${VMX_FILE}"

    # Обновляем displayName
    sed -i.bak "s/^displayName = .*/displayName = \"${VM_NAME}\"/" "${VMX_FILE}"

    # Добавляем настройки Ethernet
    for CONFIG in "${ETHERNET_CONFIG[@]}"; do
        echo "${CONFIG}" >> "${VMX_FILE}"
    done

    # Удаляем временные файлы .bak, созданные sed
    rm "${VMX_FILE}.bak"

    echo "[*] Изменения в файле ${VMX_FILE} применены:"
    echo "[**] memSize установлен в ${NEW_MEMSIZE} МБ"
    echo "[**] numvcpus установлен в ${NEW_NUMVCPUS}"
    echo "[**] displayName установлен в ${VM_NAME}"

    # Проверка наличия vmrun
    if ! command -v vmrun &> /dev/null; then
        echo "[ ] Ошибка: Команда vmrun не найдена. Убедитесь, что VMware Workstation установлена."
        exit 1
    fi

    # Запуск виртуальной машины
    echo "[*] Запуск виртуальной машины ${VM_NAME}..."
    vmrun -T ws start "${VMX_FILE}" nogui

    cd .. && echo "[*] Готово."
}

# Цикл по всем серверам и их конфигурациям
for i in "${!VM_NAMES[@]}"; do
    CONFIG_VAR="ETHERNET_CONFIGS_$((i+1))[@]"
    process_server "${VM_NAMES[$i]}" "${!CONFIG_VAR}"
done

# Одимаем завершение загрузки последней VM
sleep 60

# Сбор IP-адресов от интерфейсов VMware
vm_ips=$(ip a | awk '
    # Запоминаем имя интерфейса, если оно содержит vmnet
    /^[0-9]+: vmnet[0-9]+/ { iface = $2 }
    # Если встречаем строку с IP-адресом, выводим IP-адрес и имя интерфейса
    /inet / && iface { print $2 }
')

# Проверка наличия nmap
if ! command -v nmap &> /dev/null; then
    echo "[ ] Ошибка: Команда nmap не найдена. Убедитесь, что nmap установлен."
    exit 1
fi

# Указываем имя файла
FILE="ip.txt"

# Проверяем, существует ли файл
if [ -f "$FILE" ]; then
    rm "$FILE"
    echo "$FILE был удален."
else
    echo "$FILE не найден, создаем..."
fi

# Обрабатываем каждую IP-адресную подсеть
for ip in $vm_ips; do
    echo "[*] Сканирование сети (VMware): $ip"

    # Определяем сеть из IP-адреса
    network=$(echo $ip | cut -d'/' -f1 | awk -F. '{print $1 "." $2 "." $3 ".0/24"}')

    # Запускаем nmap для указанного диапазона
    nmap -sn $network -oG - | awk '/Up$/{if ($2 != "'$(echo $ip | cut -d'/' -f1)'") print $2}' >> "$FILE"
done

# Вставка IP-адресов из файла 'ip.txt' в файл инвентаризации Ansible (ansible/inventory/hosts)
./generate_inventory.py

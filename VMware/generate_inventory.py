#!/usr/bin/env python3

import os

# Файл с IP адресами
ip_file = 'ip.txt'

# Выходной файл для инвентаризации Ansible
inventory_file = '../ansible/inventory/hosts'

# Загрузка IP адресов из файла
with open(ip_file, 'r') as file:
    ip_addresses = [line.strip() for line in file if line.strip()]

# Подготовка данных для инвентаризации
inventory = {
    'r1_server': [],
    'r1_pc': [],
    'r2_server': [],
    'r2_pc': [],
    'r0_server': [],
}

# Простая логика для распределения IP адресов по группам
for i, ip in enumerate(ip_addresses):
    if i % 6 == 0:
        inventory['r1_server'].append(f'R1 ansible_host={ip} ansible_port=22 ansible_user=root')
    elif i % 6 == 1:
        inventory['r1_pc'].append(f'PC_R1 ansible_host={ip} ansible_port=22 ansible_user=root')
    elif i % 6 == 2:
        inventory['r2_server'].append(f'R0 ansible_host={ip} ansible_port=22 ansible_user=root')
    elif i % 6 == 3:
        inventory['r2_pc'].append(f'PC_R0 ansible_host={ip} ansible_port=22 ansible_user=root')
    elif i % 6 == 4:
        inventory['r0_server'].append(f'R2 ansible_host={ip} ansible_port=22 ansible_user=root')

# Генерация содержимого файла инвентаризации
with open(inventory_file, 'w') as file:
    for group, hosts in inventory.items():
        file.write(f'[{group}]\n')
        for host in hosts:
            file.write(f'{host}\n')
        file.write('\n')
    
    file.write('[all:children]\n')
    for group in inventory.keys():
        file.write(f'{group}\n')

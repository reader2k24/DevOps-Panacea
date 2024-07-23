# Инструкция по настройки проекта "DevOps-Panacea"

Этот раздел содержит инструкции по установке и настройке CI/CD с использованием GitLab Runner.

## 1.1 Загрузка и установка GitLab Runner

1. Загрузите двоичный файл GitLab Runner:

    ```bash
    sudo wget -O /usr/local/bin/gitlab-runner https://gitlab-runner-downloads.s3.amazonaws.com/latest/binaries/gitlab-runner-linux-amd64
    ```

2. Измените разрешения файла GitLab Runner на выполнение:

    ```bash
    sudo chmod +x /usr/local/bin/gitlab-runner
    ```

3. Создайте пользователя GitLab Runner:

    ```bash
    sudo useradd --comment 'GitLab Runner' --create-home gitlab-runner --shell /bin/bash
    ```

4. Установите и запустите GitLab Runner в качестве службы:

    ```bash
    sudo gitlab-runner install --user=gitlab-runner --working-directory=/home/gitlab-runner
    sudo gitlab-runner start
    ```

## 1.2. Настройка GitLab Runner
1. Создайте новый runner:

    ```bash
    sudo gitlab-runner register
    ```
2. Введите URL вашего экземпляра GitLab:

    ```bash
    https://gitlab.com/
    ```
3. Введите токен регистрации, который можно найти в настройках проекта GitLab:
   Settings -> CI/CD -> Runners -> Project runners -> Registration token (copy).
 
   ```bash
   [TOKEN]
   ```
5. Введите описание для runner:

    ```bash
    master server
    ```
6. Укажите теги для runner (через запятую):

    ```bash
    master
    ```
7. Опционально введите заметку для обслуживания runner.

   ```bash
   
   ```
8. Выберите тип 'executor'. В этом случае:

    ```bash
    ssh
    ```
9. Укажите адрес сервера SSH:

    ```bash
    IP
    ```
10. Укажите порт SSH сервера:

    ```bash
    PORT
    ```
11. Укажите пользователя SSH:

    ```bash
    USER
    ```
12. Введите пароль пользователя SSH:

    ```bash
    PASSWD
    ```
13. Укажите путь к файлу идентификации SSH:

    ```bash
    /[USER]/.ssh/id_rsa
    ```

## 1.3. Настройка SSH
1. Создайте файл known_hosts:

    ```bash
    touch /[USER]/.ssh/known_hosts
    ```
2. Измените разрешения файла known_hosts:
    ```bash
    chmod 600 /[USER]/.ssh/known_hosts
    ```

3. Добавьте свой собственный IP адрес в файл known_hosts:
    ```bash
    ssh-keyscan -H [IP] >> ~/.ssh/known_hosts
    ```

## 1.4. Вход по SSH (local)
1. Войдите по SSH в собстенную учетную запись:

    ```bash
    ssh [USER]@[IP] -p [PORT]
    ```
2. Добавьте свой собственный id_rsa в файл authorized_keys, при отсутсвие файла id_rsa.pub применить команду `ssh-keygen:`
    ```bash
    ssh-copy-id -i /[USER]/.ssh/id_rsa.pub -p [PORT] [USER]@[IP]
    ```
## 1.5. Проведение CI (GitLab)
Перейти в репозиторий GitLab и запустить Pipelines 
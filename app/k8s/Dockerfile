FROM nginx:latest

# Изменяем UID пользователя www-data на 1000
RUN usermod -u 1000 www-data \
    && chown -R www-data:www-data /var/cache/nginx /var/run /var/log/nginx

# Создаем новую директорию для PID файла
RUN mkdir -p /var/run/nginx

# Устанавливаем правильные разрешения для новой директории
RUN chown -R www-data:www-data /var/run/nginx

# Изменяем путь к PID файлу в настройках nginx
RUN sed -i 's#/var/run/nginx.pid#/var/run/nginx/nginx.pid#g' /etc/nginx/nginx.conf

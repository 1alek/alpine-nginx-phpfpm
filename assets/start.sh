#!/bin/bash

# Paths
php_conf=/etc/php7/php.ini
fpm_conf=/etc/php7/php-fpm.conf

# Configure PHP.INI
sed -i -e "s/upload_max_filesize.*/upload_max_filesize = ${PHP_UPLOAD_MAX_SIZE:-512M}/g" ${php_conf}
sed -i -e "s/post_max_size.*/post_max_size = ${PHP_POST_MAX_SIZE:-100M}/g" ${php_conf}
sed -i -e "s/date.timezone.*/date.timezone = ${PHP_TZ:-Europe\/Moscow}/g" ${php_conf}

# Configure PHP-FPM
sed -i -e "s/pm.max_children.*/pm.max_children = ${FPM_MAX_CHILDREN:-4}/g" ${fpm_conf}
sed -i -e "s/pm.start_servers.*/pm.start_servers = ${FPM_START_SERVERS:-1}/g" ${fpm_conf}
sed -i -e "s/pm.min_spare_servers.*/pm.min_spare_servers = ${FPM_MIN_SPARE_SERVERS:-1}/g" ${fpm_conf}
sed -i -e "s/pm.max_spare_servers.*/pm.max_spare_servers = ${FPM_MAX_SPARE_SERVERS:-2}/g" ${fpm_conf}
sed -i -e "s/pm.max_requests.*/pm.max_requests = ${FPM_MAX_REQUESTS:-500}/g" ${fpm_conf}

# Congigure NGINX
sed -i -e "s/worker_processes.*/worker_processes ${NGINX_WORKERS:-1};/g" /etc/nginx/nginx.conf
if [ ! -z "$SYSLOG_ADDR" ]; then
    echo "access_log syslog:server=${SYSLOG_ADDR} logz;" > /etc/nginx/conf.d/15-syslog.conf
fi

# Start services
exec /usr/bin/supervisord -n -c /etc/supervisord.conf

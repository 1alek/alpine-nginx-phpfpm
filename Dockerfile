FROM alpine:latest

ENV php_conf /etc/php7/php.ini 
ENV fpm_conf /etc/php7/php-fpm.conf

RUN apk add --no-cache \
    bash \
    openssh-client \
    wget \
    nginx \
    nginx-mod-http-echo \
    nginx-mod-http-upstream-fair \
    nginx-mod-http-headers-more \
    supervisor \
    curl \
    git \
    php7 \
    php7-common \
    php7-ctype \
    php7-curl \
    php7-dom \
    php7-fpm \
    php7-gd \
    php7-intl \
    php7-json \
    php7-mbstring \
    php7-mysqli \
    php7-opcache \
    php7-pdo \
    php7-session \
    php7-tidy \
    php7-tokenizer \
    php7-xml \
    php7-xmlwriter \
    php7-pear \
    php7-pecl-apcu \
    composer \
    && \
    mkdir -p /etc/nginx && \
    mkdir -p /var/www/app && \
    mkdir -p /run/nginx && \
    mkdir -p /var/log/supervisor
    # Cleanup
    # && rm -rf /var/cache/*

# Install logz
RUN curl --output /logz https://github.com/1alek/logz/releases/download/v1.3.1-99-musl/logz-musl && chmod +x /logz

# Copy startup scripts
ADD assets/supervisord.conf /etc/supervisord.conf
ADD assets/start.sh /start.sh
RUN chmod +x /start.sh

# Copy nginx configs
ADD assets/nginx.conf /etc/nginx/nginx.conf

# Configure PHP
RUN sed -i -e "s/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/g" ${php_conf} && \
    sed -i -e "s/upload_max_filesize\s*=\s*2M/upload_max_filesize = 100M/g" ${php_conf} && \
    sed -i -e "s/post_max_size\s*=\s*8M/post_max_size = 100M/g" ${php_conf} && \
    sed -i -e "s/;date.timezone =/date.timezone = Europe\/Moscow/g" ${php_conf} &&\
    sed -i -e "s/;daemonize\s*=\s*yes/daemonize = no/g" ${fpm_conf} && \
    sed -i -e "s/;catch_workers_output\s*=\s*yes/catch_workers_output = yes/g" ${fpm_conf} && \
    sed -i -e "s/;error_log = log\/php7\/error.log/error_log = \/proc\/self\/fd\/2/g" ${fpm_conf} && \
    sed -i -e "s/pm.max_children = 4/pm.max_children = 4/g" ${fpm_conf} && \
    sed -i -e "s/pm.start_servers = 2/pm.start_servers = 1/g" ${fpm_conf} && \
    sed -i -e "s/pm.min_spare_servers = 1/pm.min_spare_servers = 1/g" ${fpm_conf} && \
    sed -i -e "s/pm.max_spare_servers = 3/pm.max_spare_servers = 2/g" ${fpm_conf} && \
    sed -i -e "s/pm.max_requests = 500/pm.max_requests = 600/g" ${fpm_conf} && \
    sed -i -e "s/user = nobody/user = nginx/g" ${fpm_conf} && \
    sed -i -e "s/group = nobody/group = nginx/g" ${fpm_conf} && \
    sed -i -e "s/;listen.mode = 0660/listen.mode = 0666/g" ${fpm_conf} && \
    sed -i -e "s/;listen.owner = nobody/listen.owner = nginx/g" ${fpm_conf} && \
    sed -i -e "s/;listen.group = nobody/listen.group = nginx/g" ${fpm_conf} && \
    sed -i -e "s/listen = 127.0.0.1:9000/listen = \/var\/run\/php-fpm.sock/g" ${fpm_conf} &&\
    ln -s /etc/php7/php.ini /etc/php7/conf.d/php.ini && \
    find /etc/php7/conf.d/ -name "*.ini" -exec sed -i -re 's/^(\s*)#(.*)/\1;\2/g' {} \; && \
    ln -sf /dev/stderr /var/log/fpm-access.log && ln -sf /dev/stderr /var/log/fpm-error.log

# Init Empty Project
ADD assets/default.conf /etc/nginx/conf.d/default.conf
ADD assets/10-monitoring-basic.conf /etc/nginx/conf.d/10-monitoring-basic.conf
ADD assets/11-monitoring-logz.conf /etc/nginx/conf.d/11-monitoring-logz.conf
RUN rm -Rf /var/www/* && mkdir -p /var/www/html/ && \
    echo "<?php phpinfo();" > /var/www/html/index.php && \
    chown -R nginx. /var/www/html/

EXPOSE 80/tcp 1234/tcp
CMD ["/start.sh"]
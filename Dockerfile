FROM ubuntu:18.04

USER root

WORKDIR /var/www/html

ENV DEBIAN_FRONTEND=noninteractive
ENV LC_ALL=C.UTF-8

# RUN echo "nameserver 8.8.8.8" >> /etc/resolv.conf && \
#     echo "nameserver 4.2.2.1" >> /etc/resolv.conf

RUN apt-get update && \
    apt-get install -y --no-install-recommends apt-utils && \
    apt-get install -y software-properties-common

RUN add-apt-repository ppa:ondrej/php && \
    apt-get update && \
    apt-get upgrade -y

RUN apt-get install -y curl wget unzip apache2 openssl git npm php7.4 libapache2-mod-php php7.4-cli php7.4-intl php7.4-mysql php7.4-mbstring php7.4-zip php7.4-xml php7.4-gd php7.4-curl

COPY ./.docker/config/000-default.conf /etc/apache/sites-available

RUN sed -i "s/display_errors = Off/display_errors = On/g" /etc/php/7.4/apache2/php.ini && \
    sed -i "s/display_startup_errors = Off/display_startup_errors = On/g" /etc/php/7.4/apache2/php.ini && \
    sed -i "s/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/g" /etc/php/7.4/apache2/php.ini && \
    sed -i "s/session.use_strict_mode = 0/session.use_strict_mode = 1/g" /etc/php/7.4/apache2/php.ini && \
    sed -i "s/short_open_tag = Off/short_open_tag = On/g" /etc/php/7.4/apache2/php.ini && \
    sed -i "s/;mbstring.internal_encoding =/mbstring.internal_encoding = utf-8/g" /etc/php/7.4/apache2/php.ini && \
    sed -i "s/;opcache.revalidate_freq/opcache.revalidate_freq/g" /etc/php/7.4/apache2/php.ini && \
    sed -i "s/opcache.revalidate_freq = 0/opcache.revalidate_freq = 2/g" /etc/php/7.4/apache2/php.ini && \
    sed -i "s/;opcache.enable=1/opcache.enable=1/g" /etc/php/7.4/apache2/php.ini && \
    sed -i "s/;date.timezone =/date.timezone = Europe\/Moscow/g" /etc/php/7.4/apache2/php.ini && \
    echo 'session.save_path = "/var/www/sessions"' >> /etc/php/7.4/apache2/php.ini && \
    echo 'extension=session' >> /etc/php/7.4/apache2/php.ini && \
    echo 'magic_quotes_gpc = Off' >> /etc/php/7.4/apache2/php.ini && \
    echo 'max_input_vars = 100000' >> /etc/php/7.4/apache2/php.ini

RUN mkdir /var/www/sessions && chmod -R 777 /var/www/sessions

RUN sed -i "s;AllowOverride None;AllowOverride All;" /etc/apache2/apache2.conf

RUN chown -R www-data:www-data /var/www && \
    chmod -R g+rw /var/www

RUN php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');" && \
    HASH="$(wget -q -O - https://composer.github.io/installer.sig)" && \
    php -r "if (hash_file('SHA384', 'composer-setup.php') === '$HASH') { echo 'Installer verified'; } else { echo 'Installer corrupt'; unlink('composer-setup.php'); } echo PHP_EOL;" && \
    php composer-setup.php --install-dir=/usr/local/bin --filename=composer && rm -rf composer-setup.php

RUN apt-get update && \
    apt-get install -y php-xdebug

COPY ./.docker/config/xdebug.ini /etc/php/7.4/mods-available

RUN unset DOCKER_CERT_PATH && \
    unset DOCKER_TLS_VERIFY

# RUN apt-get update && \
#     apt-get install -y nodejs && \
#     npm rebuild node-sass && \
#     npm install -g yarn

RUN a2enmod rewrite

CMD apachectl -k graceful -D FOREGROUND

EXPOSE 80
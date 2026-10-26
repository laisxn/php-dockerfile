FROM php:8.3.36-fpm

ENV TIMEZONE Asia/Shanghai

# 配置系统时区为 Asia/Shangh 时区
RUN ln -snf /usr/share/zoneinfo/$TIMEZONE /etc/localtime && echo $TIMEZONE > /etc/timezone

# Use the default production configuration
RUN mv "$PHP_INI_DIR/php.ini-production" "$PHP_INI_DIR/php.ini"


RUN apt-get clean && apt-get update && apt-get install -y \
                libfreetype6-dev \
                libjpeg62-turbo-dev \
                libpng-dev \
                libmemcached-dev zlib1g-dev \
                libmagickwand-dev \
                libmagickcore-dev \
                libkrb5-dev \
                libzip-dev \
                curl \
                libcurl4-gnutls-dev \
        && docker-php-ext-configure gd --with-freetype=/usr/include/ --with-jpeg=/usr/include/ \
        && docker-php-ext-install -j$(nproc) gd \
        && docker-php-ext-install pdo_mysql mysqli soap bcmath pcntl sockets zip

RUN rm -r /var/lib/apt/lists/*

RUN pecl install redis \
        #&& pecl install xdebug-2.6.0 \
        && pecl install swoole \
        && pecl install mongodb \
        && pecl install memcached \
        && docker-php-ext-enable redis swoole mongodb memcached opcache

# 安装composer并允许root用户运行
ENV COMPOSER_ALLOW_SUPERUSER=1
ENV COMPOSER_NO_INTERACTION=1
ENV COMPOSER_HOME=/usr/local/share/composer
RUN mkdir -p /usr/local/share/composer \
        && curl -o /tmp/composer-setup.php https://getcomposer.org/installer \
        && php /tmp/composer-setup.php --no-ansi --install-dir=/usr/local/bin --filename=composer --snapshot \
        && rm -f /tmp/composer-setup.* \
        # 配置composer中国全量镜像
        && composer config -g repo.packagist composer https://mirrors.aliyun.com/composer/

EXPOSE 9000
CMD ["php-fpm"]

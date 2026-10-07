FROM wordpress:7.1.2-php8.4-fpm-alpine
COPY config/php.ini /usr/local/etc/php/conf.d/99-wp-base.ini
RUN set -eux; \
    apk add --no-cache curl unzip; \
    curl -fsSL -o /tmp/wp-cli.phar https://github.com/wp-cli/wp-cli/releases/download/v2.12.0/wp-cli-2.12.0.phar; \
    echo "be928f6b8ca1e8dfb9d2f4b75a13aa4aee0896f8a9a0a1c45cd5d2c98605e6172e6d014dda2e27f88c98befc16c040cbb2bd1bfa121510ea5cdf5f6a30fe8832  /tmp/wp-cli.phar" | sha512sum -c -; \
    install -m 0755 /tmp/wp-cli.phar /usr/local/bin/wp; \
    rm -f /tmp/wp-cli.phar; \
    rm -rf /usr/src/wordpress/wp-content/plugins/* /usr/src/wordpress/wp-content/themes/*; \
    curl -fsSL -o /tmp/astra.zip https://downloads.wordpress.org/theme/astra.4.14.0.zip; \
    echo "b679266036c45bbf49e709eecc1e8e894d2343f8a469c9a5537151d19ba79ced  /tmp/astra.zip" | sha256sum -c -; \
    unzip -q /tmp/astra.zip -d /usr/src/wordpress/wp-content/themes/; \
    curl -fsSL -o /tmp/google-authenticator.zip https://downloads.wordpress.org/plugin/google-authenticator.0.56.zip; \
    echo "02a91bd192f21016afce99299ff45b40d7745496779cced1b012b86d050018af  /tmp/google-authenticator.zip" | sha256sum -c -; \
    unzip -q /tmp/google-authenticator.zip -d /usr/src/wordpress/wp-content/plugins/; \
    curl -fsSL -o /tmp/wps-hide-login.zip https://downloads.wordpress.org/plugin/wps-hide-login.1.9.19.zip; \
    echo "34e99ee6032f5863b278aef690ebbfdb00290beb4eacbdae3ab931eb719b3a58  /tmp/wps-hide-login.zip" | sha256sum -c -; \
    unzip -q /tmp/wps-hide-login.zip -d /usr/src/wordpress/wp-content/plugins/; \
    rm -f /tmp/*.zip; \
    chown -R www-data:www-data /usr/src/wordpress/wp-content
WORKDIR /var/www/html

{%- from "icinga2/map.jinja" import icinga2 with context %}
{%- set config = icinga2.get('icingaweb2', {}) %}

{%- set db_user = config.get('db_user', 'icingaweb2') %}
{%- set db_password = config.get('db_password', 'icingaweb2') %}
{%- set db_name = config.get('db_name', 'icingaweb2') %}
{%- set icinga_db_user =  salt['cmd.shell']('grep -e ^dbc_dbuser= /etc/dbconfig-common/icinga2-ido-pgsql.conf | cut -d = -f 2 | sed "s/\'//g"') %}
{%- set icinga_db_password = salt['cmd.shell']('grep -e ^dbc_dbpass= /etc/dbconfig-common/icinga2-ido-pgsql.conf | cut -d = -f 2 | sed "s/\'//g"') %}
{%- set icinga_db_name =  salt['cmd.shell']('grep -e ^dbc_dbname= /etc/dbconfig-common/icinga2-ido-pgsql.conf | cut -d = -f 2 | sed "s/\'//g"') %}
{%- set users = config.get('users', {}) %}
{%- set php_timezone = config.get('php_timezone', 'Europe/Berlin') %}

include:
  - icinga2
  - icinga2.postgresql
  - icinga2.pgsql-ido

icingaweb2_pkgs:
  pkg.installed:
    - pkgs:
      - icingaweb2
      - icingaweb2-module-monitoring
      - icingacli
      - php5-pgsql
      - php5-imagick
      - php5-intl

icingaweb2-db-user:
  postgres_user.present:
    - name: {{ db_user }}
    - password: {{ db_password }}
    - require:
      - sls: icinga2.postgresql

icingaweb2-db:
  postgres_database.present:
    - name: {{ db_name }}
    - owner: {{ db_user }}
    - owner_recurse: True
    - require:
      - postgres_user: icingaweb2-db-user

icingaweb2-database-schemas:
  cmd.run:
    - name: psql -v ON_ERROR_STOP=1 --host=localhost --dbname= {{ db_name }}  --username={{ db_user }} < /usr/share/icingaweb2/etc/schema/pgsql.schema.sql
    - env:
      - PGPASSWORD: {{ db_password }}
    - require:
      - pkg: icingaweb2_pkgs
      - postgres_user: icingaweb2-db-user
    - onchanges:
      - postgres_database: icingaweb2-db

{% for username, password_hash in users.iteritems() %}

# TODO: handling for password change via pillar atm
icingaweb2-user-{{ username }}:
  cmd.run:
    - name: echo "INSERT INTO icingaweb_user (name, active, password_hash) VALUES ('{{ username }}', 1, '{{ password_hash|replace('$', '\$') }}');" | psql -v ON_ERROR_STOP=1 --host=localhost --dbname={{ db_name }} --username={{ db_user }}
    - env:
      - PGPASSWORD: {{ db_password }}
    - unless: echo "SELECT * FROM icingaweb_user where name='{{ username }}';" | psql -v ON_ERROR_STOP=1 --host=localhost --dbname={{ db_name }} --username={{ db_user }} | grep {{ username }}

{% endfor %}

php_timezone_set:
  file.append:
    - name: /etc/php5/apache2/php.ini
    - text: date.timezone="{{ php_timezone }}"

/etc/icingaweb2:
  file.recurse:
    - source: salt://icinga2/files/icingaweb2
    - template: jinja
    - user: www-data
    - group: icingaweb2
    - dir_mode: 2775
    - file_mode: 644
    - require:
      - pkg: icingaweb2_pkgs
      - sls: icinga2.pgsql-ido
    - context:
        db_user: {{ db_user }}
        db_password: {{ db_password }}
        db_name: {{ db_name }}
        icinga_db_password: {{ icinga_db_password }}
        icinga_db_user: {{ icinga_db_user }}
        icinga_db_name: {{ icinga_db_name }}
        users: {{ users }}

enable_command_feature:
  cmd.run:
    - name: icinga2 feature enable command
    - watch_in:
      - service: icinga2
    - unless: icinga2 feature list | grep Enabled | grep command

enable_monitoring_module:
  cmd.run:
    - unless: icingacli module list | grep monitoring | grep enabled
    - name: icingacli module enable monitoring
    - require:
      - pkg: icingaweb2_pkgs

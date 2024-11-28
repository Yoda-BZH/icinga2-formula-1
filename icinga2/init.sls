{% from "icinga2/map.jinja" import icinga2 with context %}


{%- if grains['os_family'] in ['Debian', 'Ubuntu'] %}
# This repository also requires Debian Backports repository
icinga2_repo:
  pkgrepo.managed:
    - humanname: Official Icinga2 package repository
    - name: deb [signed-by={{ icinga2.signed_by }}] https://{{ icinga2.repo }}/{{ salt['grains.get']('os_family')|lower }} icinga-{{ salt['grains.get']('oscodename') }} main
    - key_url: http://packages.icinga.com/icinga.key
    - file: /etc/apt/sources.list.d/icinga.list
    - clean_file: True
{%- elif grains['os_family'] == 'RedHat' %}
# TODO: RedHat repo info goes here
{%- endif %}

{%- if grains['os_family'] in ['Debian', 'Ubuntu'] %}
icinga2_keyring_pkg:
  pkg.installed:
    - name: {{ icinga2.keyring_package }}
    - require:
      - pkgrepo: icinga2_repo
{%- endif %}

icinga2_pkg:
  pkg.installed:
    - name: {{ icinga2.package }}
{%- if grains['os_family'] in ['Debian', 'Ubuntu'] %}
    - require:
      - pkg: icinga2_keyring_pkg
{%- elif grains['os_family'] == 'RedHat' %}
# TODO: RedHat repo info goes here
{%- endif %}

icinga2_service:
  service.running:
    - name: {{ icinga2.service }}
    - enable: True
    - reload: True
    - require:
      - pkg: icinga2_pkg

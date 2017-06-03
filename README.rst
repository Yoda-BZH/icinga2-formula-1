===============
icinga2-formula
===============

A salt formula that installs and configures icinga2, currently on Debian wheezy only, but other
installation source can be easily added. Configuration via pillar currently for hosts and
services only.

.. note::

Suggestions, pull-requests, bug reports and comments are welcome.

Available states
================

.. contents::
    :local:

``icinga2``
-----------

* Configure icinga2 repo
* Install icinga2 package
* Configure Icinga2 with a set of defaults
* Run icinga service

``icinga2.node``
----------------

* Run pki node
* Run config
* Run features

``icinga2.master``
------------------

* Run pki master
* Run config
* Run features

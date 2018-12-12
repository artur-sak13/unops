xrdp
=========

Ansible role to install xdrp

Role Variables
--------------

* `xrdp_desktop` - Desktop environment to install and use with xrdp
* `xrdp_xsession` - Command to start desktop environment
* `xrdp_install_gui` - Boolean signifying whether or not to install a desktop environment

Example Playbook
----------------

```yaml
- hosts: centos
  become: true
  roles:
    - { role: xrdp, tags: gui }
```

License
-------

MIT
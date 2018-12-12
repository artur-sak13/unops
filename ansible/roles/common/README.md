common
=========

Ansible role to install common packages

Role Variables
--------------

* `common_upgrade_base_defined`: Boolean signifying whether or not to update base packages

Example Playbook
----------------

```yaml
- hosts: all
  become: true
  roles:
    - role: common
```

License
-------

MIT
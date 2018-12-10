users
=========

Ansible role for managing users and groups

Role Variables
--------------

* `users` - List of users to create/update
* `users_default_shell` - Path to a users default shell
* `users_deleted` - List of users to remove
* `users_groups` - List of user groups to create
* `users_home_mode` - Default file permissions for a users's home directory

Example Playbook
----------------

```yaml
- hosts: centos
  become: true
  roles:
    - { role: users , tags: users }
```

License
-------

MIT
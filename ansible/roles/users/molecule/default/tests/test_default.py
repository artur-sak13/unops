import os

import testinfra.utils.ansible_runner

testinfra_hosts = testinfra.utils.ansible_runner.AnsibleRunner(
    os.environ['MOLECULE_INVENTORY_FILE']).get_hosts('all')


def test_groups(host):
    if not host.group('test_one').exists:
        raise AssertionError()

    if not host.group('test_two').exists:
        raise AssertionError()

    if not host.group('test_two').gid < 1000:
        raise AssertionError()

    if not host.group('test_three').exists:
        raise AssertionError()

    if not host.group('test_three').gid == 3333:
        raise AssertionError()

import os

import testinfra.utils.ansible_runner

testinfra_hosts = testinfra.utils.ansible_runner.AnsibleRunner(
    os.environ['MOLECULE_INVENTORY_FILE']).get_hosts('all')


def test_groups(host):
    assert host.group('test_one').exists

    assert host.group('test_two').exists
    assert host.group('test_two').gid < 1000

    assert host.group('test_three').exists
    assert host.group('test_three').gid == 3333

import os

import testinfra.utils.ansible_runner

testinfra_hosts = testinfra.utils.ansible_runner.AnsibleRunner(
    os.environ['MOLECULE_INVENTORY_FILE']).get_hosts('all')


def test_epel_release(package):
    epel = package('epel-release')
    assert epel.is_installed


def test_xrdp_package(package):
    xrdp = package('xrdp')
    assert xrdp.is_installed


def test_tigervnc_package(package):
    tiger = package('tigervnc-server')
    assert tiger.is_installed


def test_xrdp_running_and_enabled(service, systeminfo):
    xrdp = service('xrdp')
    assert xrdp.is_enabled
    assert xrdp.is_running


def test_xrdp_listening_tcp(host):
    socket = host.socket('tcp://0.0.0.0:3389')
    assert socket.is_listening


def test_sesman_listening_tcp(host):
    socket = host.socket('tcp://127.0.0.1:3350')
    assert socket.is_listening

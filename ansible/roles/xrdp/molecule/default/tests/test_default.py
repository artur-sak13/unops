import os

import testinfra.utils.ansible_runner

testinfra_hosts = testinfra.utils.ansible_runner.AnsibleRunner(
    os.environ['MOLECULE_INVENTORY_FILE']).get_hosts('all')


def test_epel_release(package):
    epel = package('epel-release')
    if not epel.is_installed:
        raise AssertionError()


def test_xrdp_package(package):
    xrdp = package('xrdp')
    if not xrdp.is_installed:
        raise AssertionError()


def test_tigervnc_package(package):
    tiger = package('tigervnc-server')
    if not tiger.is_installed:
        raise AssertionError()


def test_xrdp_running_and_enabled(service, systeminfo):
    xrdp = service('xrdp')
    if not xrdp.is_enabled:
        raise AssertionError()

    if not xrdp.is_running:
        raise AssertionError()


def test_xrdp_listening_tcp(host):
    socket = host.socket('tcp://0.0.0.0:3389')
    if not socket.is_listening:
        raise AssertionError()


def test_sesman_listening_tcp(host):
    socket = host.socket('tcp://127.0.0.1:3350')
    if not socket.is_listening:
        raise AssertionError()

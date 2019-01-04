from collections import namedtuple
import json
import pytest

from notify import notify

@pytest.fixture()
def cwlogs_event():
    """ Generates CloudWatch Event """

    return {
        "version": "0",
        "id": "12345678-9b15-3579-b619-7869ada6n04k",
        "detail-type": "Unops Build",
        "source": "com.unops.build",
        "account": "012345678901",
        "time": "2018-12-28T17:59:41Z",
        "region": "us-east-1",
        "resources": [
            "ami-0fd1c9a63f8fdb8a5"
        ],
        "detail": {
            "Name": "CentOS-7-1546018097",
            "AmiStatus": "Created"
        }
    }


def test_lambda_handler(cwlogs_event, mocker):
    request_response_mock = namedtuple("response", ["text"])
    request_response_mock.text = "200\n"

    request_mock = mocker.patch.object(
        notify.requests, 'post', side_effect=request_response_mock)

    ret = notify.lambda_handler(cwlogs_event, "")
    assert ret['response'] == 200

    for key in ("text", "fields"):
        assert key in ret.body

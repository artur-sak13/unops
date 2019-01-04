import os
import boto3
import json
import base64
import requests
import logging
from datetime import datetime

# ENCRYPTED_HOOK_URL = os.getenv("MATTERMOST_WEBHOOK_URL")
MATTERMOST_CHANNEL = os.getenv("MATTERMOST_CHANNEL")
MATTERMOST_USERNAME = os.getenv("MATTERMOST_USERNAME")
MATTERMOST_ICONURL = os.getenv("MATTERMOST_ICONURL")

logger = logging.getLogger()
logger.setLevel(logging.INFO)


def decrypt(encrypted_url):
    region = os.getenv("AWS_REGION")
    try:
        kms = boto3.client('kms', region_name=region)
        plaintext = kms.decrypt(CiphertextBlob=base64.b64decode(encrypted_url))[
            'Plaintext']
        return plaintext.decode('utf-8')
    except Exception:
        logger.exception("Failed to decrypt URL")


def format_date(date):
    try:
        dt = datetime.strptime(date, "%Y-%m-%dT%H:%M:%SZ")
        return dt.strftime("%a %b %d, %Y %I:%M:%S%Z %p")
    except Exception:
        logger.exception("Failed to parse datetime")


def notify_mattermost(message):
    mattermost_url = decrypt(ENCRYPTED_HOOK_URL)
    payload = {
        "channel": MATTERMOST_CHANNEL,
        "username": MATTERMOST_USERNAME,
        "icon_url": MATTERMOST_ICONURL,
        "attachments": [
            {
                'fallback': message.get('detail-type'),
                'color': '#759C3D',
                'text': 'New AMI created in {}!'.format(message.get("region")),
                'title': message.get('detail-type'),
                'title_link': 'https://gihub.com/artur-sak13/unops',
                'fields': [
                    {
                        "short": True,
                        "title": "Name",
                        "value": message.get('detail').get("Name")
                    }, {
                        "short": True,
                        "title": "Ami ID",
                        "value": message.get("resources")[0]
                    }, {
                        "short": True,
                        "title": "Region",
                        "value": message.get("region")
                    }, {
                        "short": True,
                        "title": "Creation Time",
                        "value": format_date(message.get("time"))
                    }
                ]
            }
        ]
    }
    print('DEBUG PAYLOAD:', json.dumps(payload))
    r = requests.post(mattermost_url, json=payload)
    return r.status_code


def lambda_handler(event, context):
    logger.info("Event: %s", str(event))
    return notify_mattermost(event)


if __name__ == '__main__':
    cloudwatch_event_template = json.loads(r"""
    {
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
    """)
    print(lambda_handler(cloudwatch_event_template, None))

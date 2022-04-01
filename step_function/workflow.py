#! /usr/bin/python3

import boto3
import json
import os

def handler(event, context):
    print('event: ', event)
    account = event["Input"]["account"]

    if account["state"] == "payment_late":
      print("payment reminder email sent")
      account["state"] = "reminder_sent"

    elif account["state"] == "reminder_sent":
      print("account has no arrears payments")
      account["state"] = "paid"

    return account
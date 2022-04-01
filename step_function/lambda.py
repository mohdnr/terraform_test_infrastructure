#! /usr/bin/python3

import boto3
import json
import os

accounts = list()

class Account: 
    def __init__(self, account_id, state): 
        self.account_id = account_id 
        self.state = state

class AccountEncoder(json.JSONEncoder):
    def default(self, o):
        return o.__dict__

def handler(event, context):
    print("event: ", event)
    if "Input" not in event:
      return

    payload = event["Input"]["account"]
    account_idx = get_account_idx(payload['account_id'])

    if account_idx != -1:
      print(f"account exists: {account_idx}\tstate: {accounts[account_idx].state}")

    if event["task"] == "get_account":
      if account_idx == -1:
        new_account = Account(payload['account_id'], "payment_late")
        accounts.append( new_account )
        print("account_created")
        return AccountEncoder().encode(new_account)
      else:
        return AccountEncoder().encode(accounts[account_idx])

    elif event["task"] == "update_account":
        accounts[account_idx].state = payload["state"]
    else:
        if accounts[account_idx].state == "reminder_sent":
          accounts[account_idx].state = "paid"
          print("account_paid")
        if accounts[account_idx].state == "paid":
          accounts[account_idx].state = "closed"
          return_value = AccountEncoder().encode(accounts[account_idx])
          accounts.pop(account_idx)
          print("account_closed")
          return return_value

    return AccountEncoder().encode(accounts[account_idx])

      
        

def get_account_idx(account_id):
  print("accounts: ", accounts)
  for idx, account in enumerate(accounts):
    if account.account_id == account_id:
      return idx
  
  return -1
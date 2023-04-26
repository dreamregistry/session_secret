#!/bin/bash

SECRET=$(aws secretsmanager get-random-password --query "RandomPassword" --output text --no-cli-pager)

aws ssm put-parameter \
  --name ${parameterKey} \
  --value "$SECRET" \
  --type SecureString \
  --overwrite \
  --no-cli-pager

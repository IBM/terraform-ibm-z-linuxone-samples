#!/bin/bash

set -e

set -a
source tfe.env
source ans.env
set +a

ansible-playbook \
  -i inventory.ini \
  create-tfe-initial-admin.yml
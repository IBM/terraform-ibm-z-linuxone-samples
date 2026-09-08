#!/bin/bash

set -e

set -a
source tfe.env
set +a

ansible-playbook \
  -i inventory.ini \
  install-tfe.yml
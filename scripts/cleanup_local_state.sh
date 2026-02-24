#!/bin/bash

find . -type d -name ".terraform" -exec rm -rf {} +
find . -name "terraform.tfstate*" -delete
find . -name ".terraform.lock.hcl" -delete
find . -name "tfplan" -delete

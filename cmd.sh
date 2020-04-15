#!/bin/bash

args=("$@")

update() {
    git pull https://github.com/aws-quickstart/quickstart-amazon-eks.git master --allow-unrelated-histories
}

$*
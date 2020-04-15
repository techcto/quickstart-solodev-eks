#!/bin/bash

args=("$@")

init(){
    git remote add upstream https://github.com/aws-quickstart/quickstart-amazon-eks.git
}

update() {
    git pull https://github.com/aws-quickstart/quickstart-amazon-eks.git master --allow-unrelated-histories
    git fetch upstream
    git checkout master
    git merge upstream/master
}

$*
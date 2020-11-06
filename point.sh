#!/bin/bash

echo "Update Certificates"
mkdir /usr/local/share/ca-certificates/extra
echo "${CA_CERTIFICATE}" > /usr/local/share/ca-certificates/extra/ca.crt
update-ca-certificates
echo "Certificates updated"

echo "Create workdir"
mkdir work_dir
cd work_dir/


PROJECT_NAME="$(cut -d'/' -f5 <<<"${CI_PROJECT_URL}")"
echo $PROJECT_NAME

echo "Create project dir"
mkdir $PROJECT_NAME
cd $PROJECT_NAME

echo "Move project files to project dir"
mv /builds/qa/qa_game_provider_requests/* .

cd ../

export REGISTRY_USER=$REGISTRY_USER
export REGISTRY_PASSWORD=$REGISTRY_PASSWORD
export PYPI_REPO=$PYPI_REPO
export CI_COMMIT_TAG=$CI_COMMIT_TAG

export PACKAGE_NAME=$(echo ${PROJECT_NAME} | sed "s/.*apis\///" | sed "s/\//_/g" | sed "s/-/_/g")

python ../gen.py

echo "Publishing to nexus pypi.."
python setup.py sdist upload -r nexus || exit 1
echo "Success."

#!/usr/bin/env bash


mkdir /root/.ssh
ssh-keyscan -t rsa gitlab.egt-ua.loc >> ~/.ssh/known_hosts
echo "${RSA_KEY}" > /root/.ssh/id_rsa
chmod 600 ~/.ssh/id_rsa
echo "machine gitlab.egt-ua.com login jenkins password ${BUILD_USER_ACCESS_TOKEN}" > ~/.netrc
echo "${CA_CERTIFICATE}" > /usr/local/share/ca-certificates/ca.crt
echo "${ANOTHER_ROOT_CA}" >> /usr/local/share/ca-certificates/ca2.crt
update-ca-certificates

git config --global user.email "apis-integrations@egt-ua.loc"
git config --global user.name "apis-integrations"
git config --global url."git@gitlab.egt-ua.loc:".insteadOf "https://gitlab.egt-ua.loc/"

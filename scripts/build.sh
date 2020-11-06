#!/usr/bin/env bash

if [ -z $PROJECT ]; then
    echo "no project configured"
    exit 1;
fi

if [ -z $ARTIFACT_ID ]; then
    echo "no artifact_id configured"
    exit 1;
fi

if [ -z $GROUP_ID ]; then
    echo "no group_id configured"
    exit 1;
fi

if [ -z $BRANCH ]; then
    echo "no branch specified"
    exit 1;
fi

# default prefix to project's proto path
if [ "${PATH_PREFIX}" == "" ]; then
    PATH_PREFIX='./build'
fi

HOME_DIR="/app"

apk update
apk add openssh-client python3
pip3 install python-gitlab==1.11.0

cd /app
rm -rf proto

/builds/apis/integrations/scripts/pre_build.sh

git clone -b ${BRANCH} ${PROJECT} proto

COMMIT_MESSAGE=$(echo "`date` new changes from ${USER_NAME} on ${BRANCH}")
export GEN_PROJECT=$(echo ${PROJECT} | sed "s/\/apis\//\/apis\/gen\//")

### Golang
function buildGolang {
    echo -e "\nBuilding ${GEN_PROJECT}"

    CREATE_OUTPUT=`python3 /builds/apis/integrations/scripts/create_project.py` || exit 1
    echo "$CREATE_OUTPUT"

    # 1 - if exists; 0 - if not exists
    IS_PROJECT_EXIST=$(echo ${CREATE_OUTPUT} | grep 'Project already exists' | wc -l)
    cd /app

    make build-go || exit 1

    mkdir gen

    if [[ ${IS_PROJECT_EXIST} == 0 ]];then
        newRepo ${GEN_PROJECT} "${COMMIT_MESSAGE}"
    else
        existRepo ${GEN_PROJECT} "${COMMIT_MESSAGE}"
    fi
}

function newRepo() {
    echo -e "\nGenerating for new repo"

    cd ${HOME_DIR}/gen
    echo "Dest dir: $(pwd)"
    git init
    git remote add origin $1
    git checkout -b ${BRANCH}

    collectProtobuf
    collectGoMods
    collectReadmes

    cd ${HOME_DIR}/gen
    echo "Dest dir: $(pwd)"

    git add .
    git commit -m "$2"
    if [ -z $VERSION ]; then
        git push -u origin ${BRANCH} || exit 1
    else
        git tag ${VERSION}
        if [[ ${VERSION} != v* ]]; then
            git tag v${VERSION}
        fi
        git push --tags || exit 1
    fi
}

function existRepo() {
    echo -e "\nGenerating for existed repo"

    cd ${HOME_DIR}/gen
    echo "Dest dir: $(pwd)"
    git clone $1 ${HOME_DIR}/gen
    git checkout -b ${BRANCH}

    echo "Removing old data"
    rm -rf ./*

    collectProtobuf
    collectGoMods
    collectReadmes

    cd ${HOME_DIR}/gen
    echo "Dest dir: $(pwd)"

    git add .
    git commit -m "$2"
    if [ -z $VERSION ]; then
        git push -f -u origin ${BRANCH} || exit 1
    else
        git tag ${VERSION}
        if [[ ${VERSION} != v* ]]; then
            git tag v${VERSION}
        fi
        git push --tags || exit 1
    fi
}

function collectProtobuf() {
    echo -e "\nCollecting protobuf"

    cd ${HOME_DIR}/proto/build/go/
    echo "Dest dir: $(pwd)"

    for PROTOBUF_FILE in `find ./ -type f -name "*.pb.go" -not -path './.git/*'`; do
        echo "Copy ${PROTOBUF_FILE}"
        cp -f --parents ${PROTOBUF_FILE} ${HOME_DIR}/gen/
    done
}

function collectGoMods() {
    echo -e "\nCollecting go.mod(s)"

    cd ${HOME_DIR}/proto/
    echo "Dest dir: $(pwd)"
    for ModFile in `find ./ -type f -name "go.mod" -not -path './.git/*'`; do
        echo "Copy ${ModFile}"
        cp -f --parents ${ModFile} ${HOME_DIR}/gen/
    done
}

function collectReadmes() {
    echo -e "\nCollecting README.md"

    cd ${HOME_DIR}/proto/
    echo "Dest dir: $(pwd)"
    for readmeFile in `find ./ -type f -name "README.md" -not -path './.git/*'`; do
        echo "Copy ${readmeFile}"
        cp -f --parents ${readmeFile} ${HOME_DIR}/gen/
    done
}

### Java
function buildJava() {
    echo -e "\nBuilding Java library"

    cd ${HOME_DIR}
    echo "Dest dir: $(pwd)"

    # if no VERSION is present, only SNAPSHOT version will be generated and committed/deployed
    if [ -z $VERSION ]; then
        cd ${HOME_DIR}/proto
        echo "Dest dir: $(pwd)"

        VERSION="$(echo ${BRANCH} | sed 's/\//_/g')-SNAPSHOT"
        cd ${HOME_DIR}
        echo "Dest dir: $(pwd)"
        make build-java deploy-java || exit 1

        return 0;
    fi

    make build-java deploy-java || exit 1
}


### Post actions
function branchesCleanup() {
    echo -e "\nCleaning up old branches for ${GEN_PROJECT}"

    cd ${HOME_DIR}/proto
    echo "Dest dir: $(pwd)"
    PROTO_BRANCHES=`git branch -a | grep -v 'remotes/origin/HEAD' | grep 'remotes/origin' | sed 's/remotes\/origin\///'`
    echo "PROTO_BRANCHES: `echo ${PROTO_BRANCHES} | xargs`"

    cd ${HOME_DIR}/gen
    echo "Dest dir: $(pwd)"
    GEN_BRANCHES=`git branch -a | grep -v 'remotes/origin/HEAD' | grep 'remotes/origin' | sed 's/remotes\/origin\///'`
    echo "GEN_BRANCHES: `echo ${GEN_BRANCHES} | xargs`"

    for GEN_BRANCH in ${GEN_BRANCHES}; do
        FOUND=0
        for PROTO_BRANCH in ${PROTO_BRANCHES};do
            if [ ${GEN_BRANCH} == ${PROTO_BRANCH} ];then
                FOUND=1
                break
            fi
        done
        if [ ${FOUND} == 0 ];then
            echo "Should be cleaned up: ${GEN_BRANCH}"
            git push origin --delete ${GEN_BRANCH}
        fi
        FOUND=0
    done
}

buildGolang
buildJava
branchesCleanup

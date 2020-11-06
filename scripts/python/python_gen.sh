#!/usr/bin/env bash

cd /app
echo "Project: ${PROJECT} branch: ${BRANCH}"
shopt -s extglob
for OPTION_NAME in python_grpc_out grpc_python_out
do
    git clone -b ${BRANCH} ${PROJECT} proto
    cd proto
    if [ ${OPTION_NAME} == python_grpc_out ]; then
        echo "Building asyncronous python grpc"
        PACKAGE_SUFFIX="_async"
    else
        echo "Building syncronous python grpc"
        PACKAGE_SUFFIX=""
    fi
    export PACKAGE_SUFFIX
    export PACKAGE_NAME=$(echo ${PROJECT} | sed "s/.*apis\///" | sed "s/\//_/g" | sed "s/-/_/g")$PACKAGE_SUFFIX
    echo "Package name: ${PACKAGE_NAME}"

    echo "Generating protobuf..."
    # We need to create fake project root to give resulting library custom name (instead of v1, v2 etc)
    mkdir ${PACKAGE_NAME}
    for d in */ ; do
        # remove trailing / in subdir name
        d=${d::-1}
        # fix imports to use our new root
        find ${d} -type f -exec sed -i "s/import \"$d/import \"${PACKAGE_NAME}\/$d/g" {} \;
    done

    # move proto-files to new root
    mv !(${PACKAGE_NAME}) $PACKAGE_NAME
    # generation
    python3 -m grpc_tools.protoc -I. --python_out=. --${OPTION_NAME}=. --mypy_out=. `find . -type f -name "*.proto"` || exit 1
    # add __init__.py to all subpackages
    find . -mindepth 1 -not -path '*/\.*' -type d -exec touch {}/__init__.py \;
    touch ${PACKAGE_NAME}/py.typed
    echo "Generation done."

    python /builds/apis/integrations/scripts/python/gen_configs.py

    echo "Publishing to nexus pypi.."
    python setup.py sdist upload -r nexus || exit 1
    echo "Success."
    cd ..
    rm -rf proto
done

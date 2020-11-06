#!/usr/bin/env bash

cd /app
echo "Project: ${PROJECT} branch: ${BRANCH}"
git clone -b ${BRANCH} ${PROJECT} proto

cd /app/proto
echo "Dest dir: $(pwd)"
mkdir -p ./build/js

for PROTOBUF_DIR in `find ./ -type f -name "*.proto" -not -path './.git/*'  | grep -o "\(.*\)/" | sort -u`; do
    echo "Generate ${PROTOBUF_DIR} ..."
    protoc --plugin="protoc-gen-ts=/ts/node_modules/.bin/protoc-gen-ts" --js_out="import_style=commonjs,binary:./build/js/" --ts_out="service=true:./build/js/"  -I.:${PROTOBUF_DIR} `find ${PROTOBUF_DIR} -type f -name "*.proto"` || exit 1
done

JSV=$VERSION
if [ -z $VERSION ]; then
    JSV="0.0.1"
fi
cat >./build/js/package.json <<EOL
{
"name": "@egt/${ARTIFACT_ID}-api",
"version": "${JSV}",
"author": "EGT Ukraine"
}
EOL

cd ./build/js/
npm publish --registry http://nexus.egt-ua.loc/repository/npm-registry/ || exit 1

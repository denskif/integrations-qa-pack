FROM egtukraine/protoc

ARG RSA_KEY
ARG BUILD_USER_ACCESS_TOKEN
ARG CA_CERTIFICATE
ARG ANOTHER_ROOT_CA
ARG NPM_TOKEN

ADD ./ /app

RUN apk update && apk add openssh-client
RUN apk add --update nodejs nodejs-npm
RUN npm config set unsafe-perm true
RUN mkdir /ts
WORKDIR /ts
RUN npm install ts-protoc-gen

RUN /app/scripts/pre_build.sh

RUN echo "registry=http://nexus.egt-ua.loc/repository/npm-registry/" > /root/.npmrc
RUN echo "email=you@example.com" >> /root/.npmrc
RUN echo "_auth=${NPM_TOKEN}" >> /root/.npmrc


WORKDIR /app

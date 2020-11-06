FROM python:3.6

RUN pip install protobuf==3.9.1 grpcio==1.23.0 grpcio-tools==1.23.0 grpclib==0.3.0 mypy-protobuf==1.15 googleapis-common-protos

ARG RSA_KEY
ARG BUILD_USER_ACCESS_TOKEN
ARG CA_CERTIFICATE
ARG ANOTHER_ROOT_CA
ADD ./ /app
RUN /app/scripts/pre_build.sh

WORKDIR /app

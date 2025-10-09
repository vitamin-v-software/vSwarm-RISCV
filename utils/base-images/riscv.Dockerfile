FROM debian:trixie-20250908-slim AS python-debian-base-with-grpcio-tools

RUN apt-get update && apt-get install -y python3-dev python3-pip

RUN pip install --user --break-system-packages grpcio grpcio-tools --index-url https://gitlab.com/api/v4/projects/56254198/packages/pypi/simple

FROM debian:trixie-20250908-slim AS debian-trixie

FROM debian:trixie-20250908-slim AS python-debian-base-grpc-only

RUN apt-get update && apt-get install -y python3-dev python3-pip

RUN pip install --user --break-system-packages grpcio  --index-url https://gitlab.com/api/v4/projects/56254198/packages/pypi/simple

FROM riscv64/python:3.11-trixie AS python3.11-trixie

FROM riscv64/python:3.11-slim-trixie AS python3.11-trixie-runner
#grpc 1.72 gprc  grpcio_tools-1.71.2 protobuf-5.29.5 setuptools-80

FROM python:3.13.6-slim-trixie AS python-debian-slim-runner


FROM  golang:1.21-alpine AS go-alpine-base

FROM  cartesi/node:18-jammy AS node-jammy-base

FROM natheesan/node:18.16.1-alpine AS node-alpine-runner


FROM riscv64/eclipse-temurin:17-jdk-noble AS java-17-builder

FROM riscv64/eclipse-temurin:17-jre-noble AS java-17-runner

FROM ubuntu:noble AS noble-base

FROM redis:alpine AS  redis

FROM --platform=riscv64 cartesi/python:3.10-slim-jammy AS python3.10-runner

FROM --platform=riscv64   cartesi/python:3.10-jammy AS python3.10-grpc-only-1.71
RUN pip3 install --user grpcio==1.71.0

FROM python3.10-grpc-only-1.71 AS python3.10-grpc-grpc-tools-1.71
RUN pip3 install --user grpcio-tools==1.71.0

# FROM --platform=riscv64   cartesi/python:3.10-jammy as python-jammy-grpc
# RUN pip3 install --user grpcio==1.71.0


# FROM  python-jammy-grpc AS python-jammy-grpc-tools
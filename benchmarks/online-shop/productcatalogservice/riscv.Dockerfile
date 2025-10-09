# Copyright 2020 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

FROM  --platform=riscv64  pourpourr/go-base:1.21-riscv64  AS builder
USER root
RUN apk add --no-cache ca-certificates git
RUN apk add build-base

WORKDIR /src
# restore dependencies
RUN go install github.com/grpc-ecosystem/grpc-health-probe@v0.4.10

COPY go.mod go.sum ./
RUN go mod download
COPY . .

# Skaffold passes in debug-oriented compiler flags
ARG SKAFFOLD_GO_GCFLAGS
RUN CGO_ENABLED=0 GOARCH=riscv64 GOOS=linux go build -gcflags="${SKAFFOLD_GO_GCFLAGS}" -o /productcatalogservice .

FROM  scratch as release


WORKDIR /src
COPY --from=builder /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/
COPY --from=builder /productcatalogservice ./server
COPY products.json .

# Definition of this variable is used by 'skaffold debug' to identify a golang binary.
# Default behavior - a failure prints a stack trace for the current goroutine.
# See https://golang.org/pkg/runtime/
ENV GOTRACEBACK=single

EXPOSE 3550
ENV PORT=3550
ENV DISABLE_PROFILER=true
ENV DISABLE_DEBUGGER=true
ENV DISABLE_TRACING=true
ENTRYPOINT ["/src/server"]

#entrypoint is needed .yaml
    # entrypoint:
    #   - /src/server
    #   - PORT=3550
# MIT License

# Copyright (c) 2024 EASE lab

# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:

# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.

# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

#---------- Init-Database -----------#
# First stage (Builder):
FROM  --platform=riscv64  pourpourr/go-base:1.21-riscv64 AS databaseInitBuilder
WORKDIR /app/app/
USER root
RUN apk add --no-cache ca-certificates git
RUN apk add build-base
    
    
COPY ./benchmarks/compression/init/go.mod ./
COPY ./benchmarks/compression/init/go.sum ./
COPY ./benchmarks/compression/init/riscv-init-database.go ./init-database.go
    
RUN go mod tidy
RUN CGO_ENABLED=0 GOOS=linux go build -v -o ./init-database init-database.go
    
# Second stage (Runner):
FROM scratch as databaseInit
WORKDIR /app/
COPY --from=databaseInitBuilder /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/
COPY --from=databaseInitBuilder /app/app/init-database .
COPY ./benchmarks/compression/files/ ./files
    
ENTRYPOINT [ "/app/init-database" ]

#---------- PYTHON -----------#
# First stage (Builder):
# Install gRPC and all other dependencies
FROM pourpourr/python-base:debian_grpc_only_riscv64  as compressionPython
WORKDIR /app
COPY ./benchmarks/compression/python/riscv-requirements.txt ./requirements.txt
RUN apt update && apt install -y  python3-cassandra
RUN pip3 install --break-system-packages -r requirements.txt
COPY ./utils/tracing/python/tracing.py ./
COPY ./benchmarks/compression/files/metamorphosis.txt ./
COPY ./benchmarks/compression/python/riscv-server.py ./server.py
ADD https://raw.githubusercontent.com/vhive-serverless/vSwarm-proto/main/proto/compression/compression_pb2_grpc.py ./
ADD https://raw.githubusercontent.com/vhive-serverless/vSwarm-proto/main/proto/compression/compression_pb2.py ./proto/compression/

# # Second stage (Runner):
# FROM vhiveease/python-slim:latest as compressionPython
# COPY --from=compressionPythonBuilder /root/.local /root/.local
# COPY --from=compressionPythonBuilder /py /app
# WORKDIR /app
# # ENV PATH=/root/.local/bin:$PATH
# ENTRYPOINT [ "python3", "/app/server.py" ]

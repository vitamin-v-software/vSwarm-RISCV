# MIT License

# Copyright (c) 2022 EASE lab

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

#---------- GoLang -----------#
# First stage (Builder):

FROM  --platform=riscv64  pourpourr/go-base:1.21-riscv64  AS sleepingGoBuilder
WORKDIR /app/app/
USER root
RUN  apk add git ca-certificates

COPY ./utils/tracing/go ../../utils/tracing/go
COPY ./benchmarks/sleeping/go/go.mod ./
COPY ./benchmarks/sleeping/go/go.sum ./
COPY ./benchmarks/sleeping/go/server.go ./

RUN go mod tidy
RUN CGO_ENABLED=0 GOOS=linux go build -v -o ./server server.go

# Second stage (Runner):
FROM scratch as sleepingGo
WORKDIR /app/
COPY --from=sleepingGoBuilder /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/
COPY --from=sleepingGoBuilder /app/app/server .

ENTRYPOINT [ "/app/server" ]

EXPOSE 50051
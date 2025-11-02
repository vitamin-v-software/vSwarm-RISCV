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


ROOT = ../../
DOCKER_HUB_ACCOUNT=caldiuoa

all: relay relay-docker

ARCH := $(shell uname -m)

ifeq ($(ARCH),riscv64)
    DOCKERFILE := riscv.Dockerfile
else
    DOCKERFILE := Dockerfile
endif

relay:
	go mod tidy
	go build -v -o ./server github.com/vhive-serverless/vSwarm/tools/relay

relay-docker:
	DOCKER_BUILDKIT=1 \
	docker build \
	--tag $(DOCKER_HUB_ACCOUNT)/relay:latest \
	--target relay \
	-f $(DOCKERFILE)  \
	$(ROOT)

## Push images
push:
	docker push docker.io/$(DOCKER_HUB_ACCOUNT)/relay:latest

## Pull images from docker hub
pull:
	docker pull docker.io/$(DOCKER_HUB_ACCOUNT)/relay:latest

DOCKER_HUB_ACCOUNT=pourpourr
SHELL := /bin/bash

ROOT = ../../


gptj-python-riscv-image: riscv.Dockerfile python/server.py
	DOCKER_BUILDKIT=1 docker buildx build \
		--tag $(DOCKER_HUB_ACCOUNT)/gptj-python:latest \
		-f riscv.Dockerfile \
		$(ROOT) --load

.PHONY: clean
clean:
	@rm -rf ${BUILD_DIR}

push-%: %-image
	docker push docker.io/$(DOCKER_HUB_ACCOUNT)/$(subst push-,,$@):latest

pull-%:
	docker pull docker.io/$(DOCKER_HUB_ACCOUNT)/$(subst pull-,,$@):latest
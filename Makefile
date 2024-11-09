all: build
IMAGE = devcontainers1/qt6
VERSION = v1.0.1

.PHONY: build
build:
	docker build $(BUILD_ARGS) -t $(IMAGE):$(VERSION) .

.PHONY: push
push:
	docker push $(IMAGE):$(VERSION)

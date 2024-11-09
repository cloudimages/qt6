all: build
IMAGE = devcontainers1/qt6
VERSION = latest

.PHONY: build
build:
	docker build $(BUILD_ARGS) -t $(IMAGE):$(VERSION) .

.PHONY: push
push:
	docker push $(IMAGE):$(VERSION)

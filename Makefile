
#### ARGS

IMAGE ?=
TAG ?=
ARCH_PLATFORMS ?= linux/amd64
BUILD_CACHE ?= true
HTTPS_PROXY ?=
HTTP_PROXY ?=
REGISTRY ?= docker.io

ifeq ($(BUILD_CACHE), true)
	LAYERS := '--layers'
else
	LAYERS := ''
endif

ifeq ($(REGISTRY), docker.io)
	PUSH_REGISTRY := docker:/
else
	PUSH_REGISTRY := $(REGISTRY)
endif

#### VARS

SHELL := /bin/sh
IMAGE_NAME := $(shell basename $(IMAGE) 2> /dev/null)
DOCKERFILE_DIR := src
DOCKERFILE := $(DOCKERFILE_DIR)/$(IMAGE_NAME)/Dockerfile
GIT_URL=$(shell sed -n -e 's/"//g; s/.*GIT_URL=//p' "$(DOCKERFILE)")
PROXY := HTTPS_PROXY=$(HTTPS_PROXY) HTTP_PROXY=$(HTTP_PROXY) https_proxy=$(HTTPS_PROXY) http_proxy=$(HTTP_PROXY) 
CONTAINER_TOOL := $(PROXY) buildah

#### Functions

define require_var
	$(if $(strip $($(1))),,$(error Variable $(1) is required. Usage: make $(firstword $(MAKECMDGOALS)) $(1)=<value> ...))
endef

define require_file
	$(if $(wildcard $(1)),, $(error File not found: $(1)))
endef

define print_head_info
	@printf "\n\033[1m\033[31m%-s\033[0m\n\n" "$(1)"
endef

define print_msg
	@printf "\033[1m\033[33m%-s\033[0m\n" "$(1)"
endef

.DEFAULT_GOAL := help
.PHONY: check_args ls build release build-multi release-multi help

################################################################################

check_args:
	$(call require_var,IMAGE)
	$(call require_var,TAG)
	$(call require_file,$(DOCKERFILE))

ls: ## List available Dockerfiles to build
	@ls -1 "$(DOCKERFILE_DIR)"

build: check_args ## Build image (list architectures in ARCH_PLATFORMS variable) 
	$(call require_var,ARCH_PLATFORMS)
	$(call print_msg, )
	$(call print_msg, )
	$(call print_msg, Build ENVs:)
	$(call print_msg, --------------------------------------)
	$(call print_msg, ARCH_PLATFORMS: $(ARCH_PLATFORMS))
	$(call print_msg, IMAGE: $(IMAGE))
	$(call print_msg, TAG: $(TAG))
	$(call print_msg, REGISTRY: $(REGISTRY))
	$(call print_msg, DOCKERFILE: $(DOCKERFILE))
	$(call print_msg, --------------------------------------)
	$(call print_msg, )
	$(call print_msg, )
	$(call print_msg, Additional ENVs:)
	$(call print_msg, --------------------------------------)
	$(call print_msg, BUILD_CACHE: $(BUILD_CACHE))
	$(call print_msg, HTTPS_PROXY: $(HTTPS_PROXY))
	$(call print_msg, HTTP_PROXY: $(HTTP_PROXY))
	$(call print_msg, --------------------------------------)
	$(call print_head_info, Starting build image $(REGISTRY)/$(IMAGE):$(TAG))
	@if test -n "$(GIT_URL)"; then \
		test -d "$(DOCKERFILE_DIR)/$(IMAGE_NAME)/tmp/.git"; \
		git --git-dir="$(DOCKERFILE_DIR)/$(IMAGE_NAME)/tmp/.git" pull || git clone "$(GIT_URL)" "$(DOCKERFILE_DIR)/$(IMAGE_NAME)/tmp"; \
	fi
	@$(CONTAINER_TOOL) manifest create $(IMAGE) ||:
	@$(CONTAINER_TOOL) bud $(LAYERS) --platform "$(ARCH_PLATFORMS)" --build-arg REGISTRY=$(REGISTRY) -f "$(DOCKERFILE)" -t "$(REGISTRY)/$(IMAGE):$(TAG)" -t "$(REGISTRY)/$(IMAGE):latest" --manifest $(IMAGE) "$(DOCKERFILE_DIR)/$(IMAGE_NAME)/"

release: build ## Build and push a image (list architectures in ARCH_PLATFORMS variable) 
	$(call print_head_info, Release image $(REGISTRY)/$(IMAGE):$(TAG) for platforms $(ARCH_PLATFORMS))
	@$(CONTAINER_TOOL) manifest push --all $(IMAGE) "$(PUSH_REGISTRY)/$(IMAGE):$(TAG)" # "$(REGISTRY)/$(IMAGE):$(TAG)"

help: ## Show this help message
	@echo -e '\n\033[1mSupported targets:\033[0m\n'
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) \
		| awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[33m%-12s\033[0m	%s\n", $$1, $$2}'
	@echo -e ''

################################################################################


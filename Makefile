#### ARGS

IMAGE ?=
TAG ?=
ARCH_PLATFORMS ?= 
BUILD_CACHE ?= true
HTTPS_PROXY ?=
HTTP_PROXY ?=
REGISTRY ?= docker.io
CONTAINER_ENGINE ?= buildah


ifeq ($(BUILD_CACHE), true)
	LAYERS := --layers
else
	LAYERS := 
endif

ifeq ($(REGISTRY), docker.io)
	PUSH_PREFIX := docker://
else
	PUSH_PREFIX := $(REGISTRY)/
endif

HOST := $(shell uname -m)

# Если янвно не указн ARCH_PLATFORMS, то определяем
# платформу по умолчанию на основе архитектуры хоста
ifeq ($(strip $(ARCH_PLATFORMS)),)
  ifneq (,$(filter x86_64 amd64,$(HOST)))
    override ARCH_PLATFORMS := linux/amd64
  else ifneq (,$(filter aarch64 armv8,$(HOST)))
    override ARCH_PLATFORMS := linux/arm64
  else ifneq (,$(findstring armv7,$(HOST)))
    override ARCH_PLATFORMS := linux/arm/v7
  else
    override ARCH_PLATFORMS := linux/amd64
  endif
endif

# если явно ALL (независимо от регистра) => задать полный набор
ifeq ($(strip $(shell echo $(ARCH_PLATFORMS) | tr '[:upper:]' '[:lower:]')),all)
  override ARCH_PLATFORMS := linux/arm/v7,linux/arm64,linux/amd64
endif

#### VARS

SHELL := /bin/sh
IMAGE_NAME := $(shell basename $(IMAGE) 2> /dev/null)
DOCKERFILE_DIR := $(shell readlink -f ./src)
DOCKERFILE := $(DOCKERFILE_DIR)/$(IMAGE_NAME)/Dockerfile
GIT_URL=$(shell sed -n -e 's/"//g; s/.*GIT_URL=//p' "$(DOCKERFILE)")
PROXY := HTTPS_PROXY=$(HTTPS_PROXY) HTTP_PROXY=$(HTTP_PROXY) https_proxy=$(HTTPS_PROXY) http_proxy=$(HTTP_PROXY) 

# Используем выбранный движок
CONTAINER_TOOL := $(PROXY) $(CONTAINER_ENGINE)

# Полные имена для удобства
IMAGE_TAGGED := $(REGISTRY)/$(IMAGE):$(TAG)
IMAGE_LATEST := $(REGISTRY)/$(IMAGE):latest

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
.PHONY: check_args print_args ls build release help clean

################################################################################

check_args:
	$(call require_var,IMAGE)
	$(call require_var,TAG)
	$(call require_var,ARCH_PLATFORMS)
	$(call require_file,$(DOCKERFILE))

ls: ## List available Dockerfiles to build
	@ls -1 "$(DOCKERFILE_DIR)"

print_args:
	$(call print_msg, )
	$(call print_msg, Build ENVs:)
	$(call print_msg, ------------)
	$(call print_msg, CONTAINER_ENGINE: $(CONTAINER_ENGINE))
	$(call print_msg, ARCH_PLATFORMS:   $(ARCH_PLATFORMS))
	$(call print_msg, IMAGE:            $(IMAGE))
	$(call print_msg, TAG:              $(TAG))
	$(call print_msg, REGISTRY:         $(REGISTRY))
	$(call print_msg, DOCKERFILE:       $(DOCKERFILE))
	$(call print_msg, )
	$(call print_msg, )
	$(call print_msg, Additional ENVs:)
	$(call print_msg, -----------------)
	$(call print_msg, BUILD_CACHE: $(BUILD_CACHE))
	$(call print_msg, HTTPS_PROXY: $(HTTPS_PROXY))
	$(call print_msg, HTTP_PROXY:  $(HTTP_PROXY))
	$(call print_msg, )


build: check_args print_args ## Build multi-arch image manifest
	$(call print_head_info, Starting build image $(IMAGE_TAGGED) using $(CONTAINER_ENGINE))
	@if test -n "$(GIT_URL)"; then \
		mkdir -p "$(DOCKERFILE_DIR)/$(IMAGE_NAME)/tmp"; \
		if [ -d "$(DOCKERFILE_DIR)/$(IMAGE_NAME)/tmp/.git" ]; then \
			git -C "$(DOCKERFILE_DIR)/$(IMAGE_NAME)/tmp" pull; \
		else \
			git clone "$(GIT_URL)" "$(DOCKERFILE_DIR)/$(IMAGE_NAME)/tmp"; \
		fi \
	fi
	@$(CONTAINER_TOOL) manifest rm $(IMAGE_TAGGED) 2>/dev/null ||:
	@$(CONTAINER_TOOL) manifest create $(IMAGE_TAGGED)
	@$(CONTAINER_TOOL) bud $(LAYERS) \
		--platform "$(ARCH_PLATFORMS)" \
		--build-arg REGISTRY=$(REGISTRY) \
		-f "$(DOCKERFILE)" \
		--manifest $(IMAGE_TAGGED) \
		"$(DOCKERFILE_DIR)/$(IMAGE_NAME)/"
	@if [ "$(TAG)" != "latest" ]; then \
		$(CONTAINER_TOOL) tag $(IMAGE_TAGGED) $(IMAGE_LATEST); \
	fi

release: build ## Build and push image manifest to registry
	$(call print_head_info, Releasing $(IMAGE_TAGGED) for platforms $(ARCH_PLATFORMS))
	@$(CONTAINER_TOOL) manifest push --all $(IMAGE_TAGGED) "$(PUSH_PREFIX)$(IMAGE):$(TAG)"
	@if [ "$(TAG)" != "latest" ] && [ "$(IMAGE_TAGGED)" != "$(IMAGE_LATEST)" ]; then \
		$(CONTAINER_TOOL) manifest push --all $(IMAGE_TAGGED) "$(PUSH_PREFIX)$(IMAGE):latest"; \
	fi
	$(call print_head_info, Image '$(IMAGE_TAGGED)' released)

clean: check_args ## Remove temp files and local manifests
	$(call print_msg, Cleaning up for $(IMAGE)...)
	@rm -rf "$(DOCKERFILE_DIR)/$(IMAGE_NAME)/tmp"
	@$(CONTAINER_TOOL) manifest rm $(IMAGE_TAGGED) 2>/dev/null ||:
	@$(CONTAINER_TOOL) manifest rm $(IMAGE_LATEST) 2>/dev/null ||:

help: ## Show this help message
	@echo -e '\n\033[1mSupported targets:\033[0m\n'
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) \
		| awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[33m%-12s\033[0m	%s\n", $$1, $$2}'
	@echo -e ''


#### ARGS

IMAGE ?=
TAG ?=
ARCH_PLATFORMS ?= linux/arm/v7,linux/arm64,linux/amd64
CONTAINER_MANAGER ?= docker

#### VARS

IMAGE_NAME := $(shell basename $(IMAGE) 2> /dev/null)
DOCKERFILE_DIR := src
DOCKERFILE := $(DOCKERFILE_DIR)/$(IMAGE_NAME)/Dockerfile

#### Functions

define require_var
  $(if $(strip $($(1))),,$(error Variable $(1) is required. Usage: make $(firstword $(MAKECMDGOALS)) $(1)=<value> ...))
endef

define require_file
  $(if $(wildcard $(1)),, $(error File not found: $(1)))
endef

define print_msg
   @printf "\n\033[1m\033[33m%-s\033[0m\n\n" "$(1)"
endef

.DEFAULT_GOAL := help
.PHONY: check_args list build release release-multiarch help

################################################################################

check_args:
	$(call require_var,IMAGE)
	$(call require_var,TAG)
	$(call require_file,$(DOCKERFILE))

list: ## List available Dockerfiles to build
	@ls -1 "$(DOCKERFILE_DIR)"

build: check_args ## Build local image for the current architecture
	$(call print_msg, Building image $(IMAGE):$(TAG))
	@$(CONTAINER_MANAGER) build --ulimit nofile=65536:65536 -f "$(DOCKERFILE)" -t "$(IMAGE):latest" -t "$(IMAGE):$(TAG)" $* "$(DOCKERFILE_DIR)"

release: build ## Push a single-architecture image to the registry (current arch)
	$(call print_msg, Release image $(IMAGE):$(TAG))
	@$(CONTAINER_MANAGER) push "$(IMAGE):latest" && $(CONTAINER_MANAGER) push "$(IMAGE):$(TAG)"

release-multi: check_args ## Build and push a multi-architecture image (list architectures in ARCH_PLATFORMS variable) 
	$(call require_var,ARCH_PLATFORMS)
	$(call print_msg, Release multiarch image $(IMAGE):$(TAG) for platforms $(ARCH_PLATFORMS))
	@$(CONTAINER_MANAGER) buildx build --ulimit nofile=65536:65536 -f "$(DOCKERFILE)" --push -t "$(IMAGE):$(TAG)" -t "$(IMAGE):latest" --platform "$(ARCH_PLATFORMS)" "$(DOCKERFILE_DIR)"

help: ## Show this help message
	@echo -e '\n\033[1mSupported targets:\033[0m\n'
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) \
		| awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[33m%-12s\033[0m	%s\n", $$1, $$2}'
	@echo -e ''

################################################################################


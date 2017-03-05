PROJECT_DIR := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))

CI_BUILD_NUMBER ?= $(USER)-snapshot
VERSION ?= 0.1.$(CI_BUILD_NUMBER)
PUBLISH_TAG = "meetup/k8s-nginx-dogstats:$(VERSION)"

CLUSTER ?= "your-cluster"
ZONE ?= "us-east1-b"
PROJECT ?= your-project
DATE = $(shell date +%Y-%m-%dT%H_%M_%S)

help:
	@echo Public targets:
	@grep -E '^[^_]{2}[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2}'
	@echo "Private targets: (use at own risk)"
	@grep -E '^__[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[35m%-20s\033[0m %s\n", $$1, $$2}'

__package-build:
	docker build -t $(PUBLISH_TAG) .

package: __component-test __package-build ## Create docker image and validate it against component tests.

publish: package ## Package and push to registry.
	docker push $(PUBLISH_TAG)

__deploy-only: ## [Example] Deploys to current kubectl context.
	@kubectl apply -f infra/monitoring-ns.yaml
	@PUBLISH_TAG=$(PUBLISH_TAG) \
		DATE=$(DATE) \
		envtpl < infra/k8s-nginx-dogstats-ds.yaml | kubectl apply -f -

__get-credentials:
	@gcloud container clusters get-credentials \
		--zone $(ZONE) \
		--project $(PROJECT) \
		$(CLUSTER)

deploy: __get-credentials __deploy-only ## [Example] Set K8s context to prod and deploy.

publish-tag:
	@echo $(PUBLISH_TAG)

version:
	@echo $(VERSION)

__component-test:
	$(PROJECT_DIR)/test/test-runner.sh $(PUBLISH_TAG)

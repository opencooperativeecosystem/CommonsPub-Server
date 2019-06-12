.PHONY: help dev-exports dev-build dev-deps dev-db dev-test-db dev-test dev-setup dev

APP_NAME ?= `grep 'app:' mix.exs | sed -e 's/\[//g' -e 's/ //g' -e 's/app://' -e 's/[:,]//g'`
APP_VSN ?= `grep 'version:' mix.exs | cut -d '"' -f2`
APP_BUILD ?= `git rev-parse --short HEAD`

help:
	@echo "$(APP_NAME):$(APP_VSN)-$(APP_BUILD)"
	@perl -nle'print $& if m{^[a-zA-Z_-]+:.*?## .*$$}' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

build: ## Build the Docker image
	@echo APP_NAME=$(APP_NAME)
	@echo APP_VSN=$(APP_VSN)
	@echo APP_BUILD=$(APP_BUILD)
	@echo docker build \
		--no-cache \
		--build-arg APP_NAME=$(APP_NAME) \
		--build-arg APP_VSN=$(APP_VSN) \
		--build-arg APP_BUILD=$(APP_BUILD) \
		-t moodlenet/moodlenet:$(APP_VSN)-$(APP_BUILD) .
	@docker build \
		--no-cache \
		--build-arg APP_NAME=$(APP_NAME) \
		--build-arg APP_VSN=$(APP_VSN) \
		--build-arg APP_BUILD=$(APP_BUILD) \
		-t moodlenet/moodlenet:$(APP_VSN)-$(APP_BUILD) .
	@echo moodlenet/moodlenet:$(APP_VSN)-$(APP_BUILD)

build_with_cache: ## Build the Docker image using previous cache
	@echo APP_NAME=$(APP_NAME)
	@echo APP_VSN=$(APP_VSN)
	@echo APP_BUILD=$(APP_BUILD)
	@echo docker build \
		--build-arg APP_NAME=$(APP_NAME) \
		--build-arg APP_VSN=$(APP_VSN) \
		--build-arg APP_BUILD=$(APP_BUILD) \
		-t moodlenet/moodlenet:$(APP_VSN)-$(APP_BUILD) .
	@docker build \
		--build-arg APP_NAME=$(APP_NAME) \
		--build-arg APP_VSN=$(APP_VSN) \
		--build-arg APP_BUILD=$(APP_BUILD) \
		-t moodlenet/moodlenet:$(APP_VSN)-$(APP_BUILD) .
	@echo moodlenet/moodlenet:$(APP_VSN)-$(APP_BUILD)

push: ## Add latest tag to last build and push
	@echo docker tag moodlenet/moodlenet:$(APP_VSN)-$(APP_BUILD) moodlenet/moodlenet:latest
	@docker tag moodlenet/moodlenet:$(APP_VSN)-$(APP_BUILD) moodlenet/moodlenet:latest
	@echo docker push moodlenet/moodlenet:latest
	@docker push moodlenet/moodlenet:latest

push_stable: ## Tag stable, latest and version tags to the last build and push
	@echo docker tag moodlenet/moodlenet:$(APP_VSN)-$(APP_BUILD) moodlenet/moodlenet:latest
	@docker tag moodlenet/moodlenet:$(APP_VSN)-$(APP_BUILD) moodlenet/moodlenet:latest
	@echo docker tag moodlenet/moodlenet:$(APP_VSN)-$(APP_BUILD) moodlenet/moodlenet:$(APP_VSN)
	@docker tag moodlenet/moodlenet:$(APP_VSN)-$(APP_BUILD) moodlenet/moodlenet:$(APP_VSN)
	@echo docker tag moodlenet/moodlenet:$(APP_VSN)-$(APP_BUILD) moodlenet/moodlenet:stable
	@docker tag moodlenet/moodlenet:$(APP_VSN)-$(APP_BUILD) moodlenet/moodlenet:stable
	@echo docker push moodlenet/moodlenet:latest
	@docker push moodlenet/moodlenet:latest
	@echo docker push moodlenet/moodlenet:stable
	@docker push moodlenet/moodlenet:stable
	@echo docker push moodlenet/moodlenet:$(APP_VSN)
	@docker push moodlenet/moodlenet:$(APP_VSN)
	@echo docker push moodlenet/moodlenet:$(APP_VSN)-$(APP_BUILD)
	@docker push moodlenet/moodlenet:$(APP_VSN)-$(APP_BUILD)

dev-exports:
	awk '{print "export " $$0}' config/docker.dev.env

dev-build:
	docker-compose -f docker-compose.dev.yml build web

dev-rebuild:
	docker-compose -f docker-compose.dev.yml build --no-cache web


dev-deps:
	docker-compose -f docker-compose.dev.yml run web mix local.hex --force
	docker-compose -f docker-compose.dev.yml run web mix local.rebar --force
	docker-compose -f docker-compose.dev.yml run web mix deps.get

dev-db:
	docker-compose -f docker-compose.dev.yml run web mix ecto.reset

dev-test-db:
	docker-compose -f docker-compose.dev.yml -e MIX_ENV=test run web mix ecto.reset

dev-test:
	docker-compose -f docker-compose.dev.yml run web mix test

dev-setup: dev-deps dev-db

dev:
	docker-compose -f docker-compose.dev.yml run --service-ports web

manual-deps:
	mix local.hex --force
	mix local.rebar --force
	mix deps.get

manual-db:
	mix ecto.reset

run: ## Run the app in Docker
	docker run\
		--env-file config/docker.env \
		--expose 4000 -p 4000:4000 \
		--link db \
		--rm -it moodlenet/moodlenet:$(APP_VSN)-$(APP_BUILD)

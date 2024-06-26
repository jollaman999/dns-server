SHELL = /bin/bash

MODULE_NAME := "dns-server"
PROJECT_NAME := "github.com/jollaman999/${MODULE_NAME}"
PKG_LIST := $(shell go list ${PROJECT_NAME}/... 2>&1)

GOPROXY_OPTION := GOPROXY=direct GOSUMDB=off
GO_COMMAND := ${GOPROXY_OPTION} go
GOPATH := $(shell go env GOPATH)

.PHONY: all dependency lint test race coverage coverhtml gofmt update build run run_docker stop_docker clean help

all: build

dependency: ## Get dependencies
	@echo Checking dependencies...
	@${GO_COMMAND} mod tidy

lint: dependency ## Lint the files
	@echo "Running linter..."
	@go_path=${GOPATH}; \
	  kernel_name=`uname -s` && \
	  if [[ $$kernel_name == "CYGWIN"* ]] || [[ $$kernel_name == "MINGW"* ]]; then \
	    drive=`go env GOPATH | cut -f1 -d':' | tr '[:upper:]' '[:lower:]'`; \
	    path=`go env GOPATH | cut -f2 -d':' | sed 's@\\\\@\/@g'`; \
	    cygdrive_prefix=`mount -p | tail -n1 | awk '{print $$1}'`; \
	    go_path="$$cygdrive_prefix/$$drive/$$path"; \
	  fi; \
	  if [ ! -f "$$go_path/bin/golangci-lint" ]; then \
	    ${GO_COMMAND} install github.com/golangci/golangci-lint/cmd/golangci-lint@latest; \
	  fi; \
	  $$go_path/bin/golangci-lint run -E contextcheck -E revive

test: dependency ## Run unittests
	@echo "Running tests..."
	@${GO_COMMAND} test -v ${PKG_LIST}

race: dependency ## Run data race detector
	@echo "Checking races..."
	@${GO_COMMAND} test -race -v ${PKG_LIST}

coverage: dependency ## Generate global code coverage report
	@echo "Generating coverage report..."
	@${GO_COMMAND} test -v -coverprofile=coverage.out ${PKG_LIST}
	@${GO_COMMAND} tool cover -func=coverage.out

coverhtml: coverage ## Generate global code coverage report in HTML
	@echo "Generating coverage report in HTML..."
	@${GO_COMMAND} tool cover -html=coverage.out

gofmt: ## Run gofmt for go files
	@echo "Running gofmt..."
	@find -type f -name '*.go' -not -path "./vendor/*" -exec $(GOROOT)/bin/gofmt -s -w {} \;

update: ## Update all of module dependencies
	@echo Updating dependencies...
	@cd cmd/${MODULE_NAME} && ${GO_COMMAND} get -u
	@echo Checking dependencies...
	@${GO_COMMAND} mod tidy

build: lint ## Build the binary file
	@echo Building...
	@kernel_name=`uname -s` && \
	  if [[ $$kernel_name == "Linux" ]]; then \
	    cd cmd/${MODULE_NAME} && CGO_ENABLED=0 ${GO_COMMAND} build -o ${MODULE_NAME} main.go; \
	  elif [[ $$kernel_name == "CYGWIN"* ]] || [[ $$kernel_name == "MINGW"* ]]; then \
	    cd cmd/${MODULE_NAME} && GOOS=windows CGO_ENABLED=0 ${GO_COMMAND} build -o ${MODULE_NAME}.exe main.go; \
	  else \
	    echo $$kernel_name; \
	    echo "Not supported Operating System. ($$kernel_name)"; \
	  fi
	@git diff > .diff_last_build
	@git rev-parse HEAD > .git_hash_last_build
	@echo Build finished!

run: ## Run the built binary
	@git diff > .diff_current
	@STATUS=`diff .diff_last_build .diff_current 2>&1 > /dev/null; echo $$?` && \
	  GIT_HASH_MINE=`git rev-parse HEAD` && \
	  GIT_HASH_LAST_BUILD=`cat .git_hash_last_build 2>&1 > /dev/null | true` && \
	  if [ "$$STATUS" != "0" ] || [ "$$GIT_HASH_MINE" != "$$GIT_HASH_LAST_BUILD" ]; then \
	    $(MAKE) build; \
	  fi
	@cp -RpPf conf cmd/${MODULE_NAME}/ && ./cmd/${MODULE_NAME}/${MODULE_NAME}* || echo "Trying with sudo..." && sudo ./cmd/${MODULE_NAME}/${MODULE_NAME}*

run_docker: ## Run the built binary within Docker
	@git diff > .diff_current
	@STATUS=`diff .diff_last_build .diff_current 2>&1 > /dev/null; echo $$?` && \
	  GIT_HASH_MINE=`git rev-parse HEAD` && \
	  GIT_HASH_LAST_BUILD=`cat .git_hash_last_build 2>&1 > /dev/null | true` && \
	  if [ "$$STATUS" != "0" ] || [ "$$GIT_HASH_MINE" != "$$GIT_HASH_LAST_BUILD" ]; then \
	    $(MAKE) build; \
	  fi
	@cp -pPf ./cmd/${MODULE_NAME}/${MODULE_NAME} ./
	@docker compose up -d

stop_docker: ## Stop the Docker container
	@docker compose down

clean: ## Remove previous build
	@echo Cleaning build...
	@rm -f coverage.out
	@rm -f pkg/api/rest/docs/docs.go pkg/api/rest/docs/swagger.*
	@rm -rf cmd/${MODULE_NAME}/conf
	@cd cmd/${MODULE_NAME} && ${GO_COMMAND} clean

help: ## Display this help screen
	@grep -h -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

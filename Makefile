.PHONY: build-RuntimeDependenciesLayer build-lambda-common
.PHONY: build-getAllItemsFunction build-getByIdFunction build-putItemFunction

build-getAllItemsFunction: build-lambda-common
build-getByIdFunction: build-lambda-common
build-putItemFunction: build-lambda-common

build-lambda-common:
	cp -r src "$(ARTIFACTS_DIR)/"

build-RuntimeDependenciesLayer:
	mkdir -p "$(ARTIFACTS_DIR)/nodejs"
	cp package.json package-lock.json "$(ARTIFACTS_DIR)/nodejs/"
	npm install --production --prefix "$(ARTIFACTS_DIR)/nodejs/"
	rm "$(ARTIFACTS_DIR)/nodejs/package.json" # to avoid rebuilding when changes doesn't relate to dependencies

.PHONY: build-RuntimeDependenciesLayer build-lambda-common
.PHONY: build-getAllItemsFunction build-getByIdFunction build-putItemFunction

build-getAllItemsFunction:
	$(MAKE) HANDLER=src/handlers/get-all-items.ts build-lambda-common
build-getByIdFunction:
	$(MAKE) HANDLER=src/handlers/get-by-id.ts build-lambda-common
build-putItemFunction:
	$(MAKE) HANDLER=src/handlers/put-item.ts build-lambda-common
build-writeItemFunction:
	$(MAKE) HANDLER=src/handlers/write-item.ts build-lambda-common

build-lambda-common:
	npm install
	rm -rf dist
	printf "{\"extends\": \"./tsconfig.json\", \"include\": [\"${HANDLER}\"] }" > tsconfig-only-handler.json
	npm run build -- --build tsconfig-only-handler.json
	cp -r dist "$(ARTIFACTS_DIR)/"

build-RuntimeDependenciesLayer:
	mkdir -p "$(ARTIFACTS_DIR)/nodejs"
	cp package.json package-lock.json "$(ARTIFACTS_DIR)/nodejs/"
	npm install --production --prefix "$(ARTIFACTS_DIR)/nodejs/"
	rm "$(ARTIFACTS_DIR)/nodejs/package.json"

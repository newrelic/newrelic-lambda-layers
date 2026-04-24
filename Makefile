build-java8al2:
	docker build \
		--no-cache \
		-t newrelic-lambda-layers-java8al2 \
		-f ./dockerfiles/Dockerfile.java8al2 \
		.

publish-java8al2-ci: build-java8al2
	docker run \
		-e AWS_ACCESS_KEY_ID \
		-e AWS_SECRET_ACCESS_KEY \
		newrelic-lambda-layers-java8al2

publish-java8al2-local: build-java8al2
	docker run \
		-e AWS_PROFILE \
		-v "${HOME}/.aws:/home/newrelic-lambda-layers/.aws" \
		newrelic-lambda-layers-java8al2

build-java11:
	docker build \
		--no-cache \
		-t newrelic-lambda-layers-java11 \
		-f ./dockerfiles/Dockerfile.java11 \
		.

publish-java11-ci: build-java11
	docker run \
		-e AWS_ACCESS_KEY_ID \
		-e AWS_SECRET_ACCESS_KEY \
		newrelic-lambda-layers-java11

publish-java11-local: build-java11
	docker run \
		-e AWS_PROFILE \
		-v "${HOME}/.aws:/home/newrelic-lambda-layers/.aws" \
		newrelic-lambda-layers-java11

build-java17:
	docker build \
		--no-cache \
		-t newrelic-lambda-layers-java17 \
		-f ./dockerfiles/Dockerfile.java17 \
		.

publish-java17-ci: build-java17
	docker run \
		-e AWS_ACCESS_KEY_ID \
		-e AWS_SECRET_ACCESS_KEY \
		newrelic-lambda-layers-java17

publish-java17-local: build-java17
	docker run \
		-e AWS_PROFILE \
		-v "${HOME}/.aws:/home/newrelic-lambda-layers/.aws" \
		newrelic-lambda-layers-java17

build-java21:
	docker build \
		--no-cache \
		-t newrelic-lambda-layers-java21 \
		-f ./dockerfiles/Dockerfile.java21 \
		.

publish-java21-ci: build-java21
	docker run \
		-e AWS_ACCESS_KEY_ID \
		-e AWS_SECRET_ACCESS_KEY \
		newrelic-lambda-layers-java21

publish-java21-local: build-java21
	docker run \
		-e AWS_PROFILE \
		-v "${HOME}/.aws:/home/newrelic-lambda-layers/.aws" \
		newrelic-lambda-layers-java21

extract-java21-artifacts: build-java21
	@docker rm -f java21-artifacts 2>/dev/null || true
	mkdir -p dist/java21
	docker create --name java21-artifacts newrelic-lambda-layers-java21
	docker cp java21-artifacts:/home/newrelic-lambda-layers/java/dist/. dist/java21/
	docker rm java21-artifacts

build-nodejs20:
	docker build \
		--no-cache \
		-t newrelic-lambda-layers-nodejs20 \
		-f ./dockerfiles/Dockerfile.nodejs20 \
		.

publish-nodejs20-ci: build-nodejs20
	docker run \
		-e AWS_ACCESS_KEY_ID \
		-e AWS_SECRET_ACCESS_KEY \
		newrelic-lambda-layers-nodejs20

publish-nodejs20-local: build-nodejs20
	docker run \
		-e AWS_PROFILE \
		-v "${HOME}/.aws:/home/newrelic-lambda-layers/.aws" \
		newrelic-lambda-layers-nodejs20

build-nodejs22:
	docker build \
		--no-cache \
		-t newrelic-lambda-layers-nodejs22 \
		-f ./dockerfiles/Dockerfile.nodejs22 \
		.

publish-nodejs22-ci: build-nodejs22
	docker run \
		-e AWS_ACCESS_KEY_ID \
		-e AWS_SECRET_ACCESS_KEY \
		newrelic-lambda-layers-nodejs22

publish-nodejs22-local: build-nodejs22
	docker run \
		-e AWS_PROFILE \
		-v "${HOME}/.aws:/home/newrelic-lambda-layers/.aws" \
		newrelic-lambda-layers-nodejs22

build-nodejs24:
	docker build \
		--no-cache \
		-t newrelic-lambda-layers-nodejs24 \
		-f ./dockerfiles/Dockerfile.nodejs24 \
		.

publish-nodejs24-ci: build-nodejs24
	docker run \
		-e AWS_ACCESS_KEY_ID \
		-e AWS_SECRET_ACCESS_KEY \
		newrelic-lambda-layers-nodejs24

publish-nodejs24-local: build-nodejs24
	docker run \
		-e AWS_PROFILE \
		-v "${HOME}/.aws:/home/newrelic-lambda-layers/.aws" \
		newrelic-lambda-layers-nodejs24

# Extract built zips from the Docker image into dist/nodejs<N>/ for staging publish.
extract-nodejs20-artifacts: build-nodejs20
	@docker rm -f nodejs20-artifacts 2>/dev/null || true
	mkdir -p dist/nodejs20
	docker create --name nodejs20-artifacts newrelic-lambda-layers-nodejs20
	docker cp nodejs20-artifacts:/home/newrelic-lambda-layers/nodejs/dist/. dist/nodejs20/
	docker rm nodejs20-artifacts

extract-nodejs22-artifacts: build-nodejs22
	@docker rm -f nodejs22-artifacts 2>/dev/null || true
	mkdir -p dist/nodejs22
	docker create --name nodejs22-artifacts newrelic-lambda-layers-nodejs22
	docker cp nodejs22-artifacts:/home/newrelic-lambda-layers/nodejs/dist/. dist/nodejs22/
	docker rm nodejs22-artifacts

extract-nodejs24-artifacts: build-nodejs24
	@docker rm -f nodejs24-artifacts 2>/dev/null || true
	mkdir -p dist/nodejs24
	docker create --name nodejs24-artifacts newrelic-lambda-layers-nodejs24
	docker cp nodejs24-artifacts:/home/newrelic-lambda-layers/nodejs/dist/. dist/nodejs24/
	docker rm nodejs24-artifacts

build-python-universal:
	docker build \
		--no-cache \
		-t newrelic-lambda-layers-python \
		-f ./dockerfiles/Dockerfile.python \
		.

publish-python-universal-ci: build-python-universal
	docker run \
		-e AWS_ACCESS_KEY_ID \
		-e AWS_SECRET_ACCESS_KEY \
		newrelic-lambda-layers-python

publish-python-universal-local: build-python-universal
	docker run \
		-e AWS_PROFILE \
		-v "${HOME}/.aws:/home/newrelic-lambda-layers/.aws" \
		newrelic-lambda-layers-python

build-nodejs-universal:
	docker build \
		--no-cache \
		-t newrelic-lambda-layers-nodejs \
		-f ./dockerfiles/Dockerfile.nodejs \
		.

publish-nodejs-universal-ci: build-nodejs-universal
	docker run \
		-e AWS_ACCESS_KEY_ID \
		-e AWS_SECRET_ACCESS_KEY \
		newrelic-lambda-layers-nodejs

publish-nodejs-universal-local: build-nodejs-universal
	docker run \
		-e AWS_PROFILE \
		-v "${HOME}/.aws:/home/newrelic-lambda-layers/.aws" \
		newrelic-lambda-layers-nodejs

build-ruby32:
	docker build \
		--no-cache \
		-t newrelic-lambda-layers-ruby32 \
		-f ./dockerfiles/Dockerfile.ruby32 \
		.

publish-ruby32-ci: build-ruby32
	docker run \
		-e AWS_ACCESS_KEY_ID \
		-e AWS_SECRET_ACCESS_KEY \
		newrelic-lambda-layers-ruby32

publish-ruby32-local: build-ruby32
	docker run \
		-e AWS_PROFILE \
		-v "${HOME}/.aws:/home/newrelic-lambda-layers/.aws" \
		newrelic-lambda-layers-ruby32

build-ruby33:
	docker build \
		--no-cache \
		-t newrelic-lambda-layers-ruby33 \
		-f ./dockerfiles/Dockerfile.ruby33 \
		.

publish-ruby33-ci: build-ruby33
	docker run \
		-e AWS_ACCESS_KEY_ID \
		-e AWS_SECRET_ACCESS_KEY \
		newrelic-lambda-layers-ruby33

publish-ruby33-local: build-ruby33
	docker run \
		-e AWS_PROFILE \
		-v "${HOME}/.aws:/home/newrelic-lambda-layers/.aws" \
		newrelic-lambda-layers-ruby33

build-ruby34:
	docker build \
		--no-cache \
		-t newrelic-lambda-layers-ruby34 \
		-f ./dockerfiles/Dockerfile.ruby34 \
		.

publish-ruby34-ci: build-ruby34
	docker run \
		-e AWS_ACCESS_KEY_ID \
		-e AWS_SECRET_ACCESS_KEY \
		newrelic-lambda-layers-ruby34

publish-ruby34-local: build-ruby34
	docker run \
		-e AWS_PROFILE \
		-v "${HOME}/.aws:/home/newrelic-lambda-layers/.aws" \
		newrelic-lambda-layers-ruby34
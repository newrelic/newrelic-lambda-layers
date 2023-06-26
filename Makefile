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

build-nodejs14x:
	docker build \
		--no-cache \
		-t newrelic-lambda-layers-nodejs14x \
		-f ./dockerfiles/Dockerfile.nodejs14x \
		.

publish-nodejs14x-ci: build-nodejs14x
	docker run \
		-e AWS_ACCESS_KEY_ID \
		-e AWS_SECRET_ACCESS_KEY \
		newrelic-lambda-layers-nodejs14x

publish-nodejs14x-local: build-nodejs14x
	docker run \
		-e AWS_PROFILE \
		-v "${HOME}/.aws:/home/newrelic-lambda-layers/.aws" \
		newrelic-lambda-layers-nodejs14x

build-nodejs16x:
	docker build \
		--no-cache \
		-t newrelic-lambda-layers-nodejs16x \
		-f ./dockerfiles/Dockerfile.nodejs16x \
		.

publish-nodejs16x-ci: build-nodejs16x
	docker run \
		-e AWS_ACCESS_KEY_ID \
		-e AWS_SECRET_ACCESS_KEY \
		newrelic-lambda-layers-nodejs16x

publish-nodejs16x-local: build-nodejs16x
	docker run \
		-e AWS_PROFILE \
		-v "${HOME}/.aws:/home/newrelic-lambda-layers/.aws" \
		newrelic-lambda-layers-nodejs16x

build-nodejs18x:
	docker build \
		--no-cache \
		-t newrelic-lambda-layers-nodejs18x \
		-f ./dockerfiles/Dockerfile.nodejs18x \
		.

publish-nodejs18x-ci: build-nodejs18x
	docker run \
		-e AWS_ACCESS_KEY_ID \
		-e AWS_SECRET_ACCESS_KEY \
		newrelic-lambda-layers-nodejs18x

publish-nodejs18x-local: build-nodejs18x
	docker run \
		-e AWS_PROFILE \
		-v "${HOME}/.aws:/home/newrelic-lambda-layers/.aws" \
		newrelic-lambda-layers-nodejs18x

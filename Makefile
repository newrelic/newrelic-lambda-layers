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

build-nodejs16:
	docker build \
		--no-cache \
		-t newrelic-lambda-layers-nodejs16 \
		-f ./dockerfiles/Dockerfile.nodejs16 \
		.

publish-nodejs16-ci: build-nodejs16
	docker run \
		-e AWS_ACCESS_KEY_ID \
		-e AWS_SECRET_ACCESS_KEY \
		newrelic-lambda-layers-nodejs16

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
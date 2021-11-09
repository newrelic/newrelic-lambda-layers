build-nodejs12x:
	docker build \
		--no-cache \
		-t newrelic-lambda-layers-nodejs12x \
		-f ./dockerfiles/Dockerfile.nodejs12x \
		.

publish-nodejs12x-ci: build-nodejs12x
	docker run \
		-e AWS_ACCESS_KEY_ID \
		-e AWS_SECRET_ACCESS_KEY \
		newrelic-lambda-layers-nodejs12x

publish-nodejs12x-local: build-nodejs12x
	docker run \
		-e AWS_PROFILE \
		-v "${HOME}/.aws:/home/newrelic-lambda-layers/.aws" \
		newrelic-lambda-layers-nodejs12x

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

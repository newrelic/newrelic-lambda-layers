FROM alpine:latest as layer-copy

ARG layer_zip
ARG file_without_dist

RUN apk update && apk add --no-cache curl unzip

WORKDIR /

COPY ${layer_zip} .

RUN unzip ${file_without_dist} -d ./opt
RUN rm ${file_without_dist}

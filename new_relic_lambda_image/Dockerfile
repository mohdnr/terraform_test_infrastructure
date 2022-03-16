FROM python:3.9-alpine3.13

ENV PYTHONPATH "${PYTHONPATH}:/opt/python/lib/python3.9/site-packages"
ENV PYTHONDONTWRITEBYTECODE 1

RUN apk add --no-cache bash build-base git libtool cmake autoconf automake gcc musl-dev postgresql-dev g++ libc6-compat libexecinfo-dev make libffi-dev libmagic libcurl curl-dev rust cargo && rm -rf /var/cache/apk/*

# update pip
RUN python -m pip install wheel
RUN python -m pip install --upgrade pip

RUN set -ex && mkdir /app

COPY ./newrelic-layer.zip /tmp/newrelic-layer.zip
RUN unzip /tmp/newrelic-layer.zip -d /opt && rm /tmp/newrelic-layer.zip

WORKDIR /app

COPY requirements.txt /app
RUN set -ex && pip3 install -r requirements.txt
RUN pip3 install awslambdaric newrelic-lambda

COPY . /app

ENV PORT=6011

ARG GIT_SHA
ENV GIT_SHA ${GIT_SHA}

# (Optional) Add Lambda Runtime Interface Emulator and use a script in the ENTRYPOINT for simpler local runs
ADD https://github.com/aws/aws-lambda-runtime-interface-emulator/releases/latest/download/aws-lambda-rie /usr/bin/aws-lambda-rie
COPY bin/entry.sh /
RUN chmod 755 /usr/bin/aws-lambda-rie /entry.sh

ENTRYPOINT [ "/entry.sh" ]
CMD [ "newrelic_lambda_wrapper.handler" ]
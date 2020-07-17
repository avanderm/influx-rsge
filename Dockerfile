FROM python:3.8.4-alpine

# RUN apk add --no-cache \
RUN apk add \
    libxml2 \
    libxml2-dev \
    libxslt \
    libxslt-dev \
    g++

COPY requirements.txt requirements.txt
RUN pip install --no-cache-dir -r requirements.txt
COPY src src

# ENTRYPOINT [ "python" ]
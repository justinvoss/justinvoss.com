
FROM ubuntu:23.10

RUN apt-get update && \
  DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    ruby-full \
    build-essential \
    zlib1g-dev \
  && \
  apt-get -y autoremove --purge && \
  apt-get -y clean && \
  rm -rf /var/lib/apt/lists/* /var/cache/apt/apt-file/* && \
  gem install jekyll bundler

WORKDIR /jekyll/
EXPOSE 4000

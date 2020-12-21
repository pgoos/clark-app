#
# base image
#
FROM ruby:2.6.3-alpine3.9 as base

RUN apk update
RUN apk --no-cache add \
  imagemagick \
  tzdata \
  nodejs

#
# builder
#
FROM base as Builder

ARG RAILS_ENV=production
ARG APP

# check that APP (brand) argument is not empty
RUN test -n "$APP"

RUN apk --no-cache add \
  build-base \
  postgresql-dev \
  git \
  linux-headers

WORKDIR /app

COPY Gemfile* /app/
COPY gems/ /app/gems/
ENV RAILS_APPLICATION_SERVER puma

RUN echo "gem: --no-document" > ~/.gemrc && \
  bundle config --global frozen 1 && \
  gem install bundler -v 1.15.1 --no-document && \
  bundle install --without development test --jobs 4 --retry 3 && \
  rm -rf /usr/local/bundle/cache/*.gem

COPY config/database.yml.docker /app/config/database.yml
COPY . /app/

ENV RAILS_ENV=${RAILS_ENV}
ENV APP=${APP}
ENV AWS_REGION=eu-central-1
ENV AWS_ACCESS_KEY=pseudo_for_compile
ENV AWS_SECRET=pseudo_for_compile
ENV DEVISE_SECRET_KEY=pseudo_for_compile
ENV DB_ADAPTER=nulldb

RUN bundle exec rake assets:precompile

#
#
# Build Client Ops Client
#
FROM node:12.14.1-alpine3.11 as ClientOpsBuilder

RUN apk --no-cache add \
  git

RUN npm config set unsafe-perm true
RUN npm install --force -g yarn

ARG APP
ARG LOCAL_URLS_ONLY

RUN test -n "$APP"

WORKDIR /app/

COPY --from=Builder /app /app

RUN yarn install --frozen-lockfile --non-interactive

# Keep in sync with:
# - deploy/before_symlink.rb
# - .circleci/config.yml
ENV NODE_OPTIONS --max-old-space-size=4096

ENV NODE_ENV production
ENV EMBER_ENV production
ENV CLIENT_OPS_PATH /app/client-ops/offer-rule-matrix
ENV APP ${APP}
ENV LOCAL_URLS_ONLY ${LOCAL_URLS_ONLY}

RUN cd /app/client-ops/offer-rule-matrix && yarn run build && \
  cd /app/client && yarn run build

RUN mkdir -p /app/public/assets/client-ops/@clarksource/offer-rule-matrix /app/public/assets/client && \
  cp -r /app/client-ops/offer-rule-matrix/dist/* /app/public/assets/client-ops/@clarksource/offer-rule-matrix && \
  cp -r /app/client/dist/* /app/public/assets/client

RUN rm -rf /app/node_modules \
  /app/client* \
  /app/log/* \
  /app/tmp/*

#
#
# Build Production Image
#
FROM base

# nodejs is required to load coffescript-rails and uglifier gems
RUN apk --no-cache add \
  file \
  postgresql-client \
  libcrypto1.1 libssl1.1 \
  libgcc libstdc++ libx11 glib libxrender libxext libintl \
  ttf-dejavu ttf-droid ttf-freefont ttf-liberation ttf-ubuntu-font-family \
  vim wget gnupg htop nmap ncdu
RUN rm -rf /var/cache/apk/*

RUN addgroup -g 1000 -S deploy && \
  adduser -u 1000 -S deploy -G deploy && \
  mkdir -p /app && chown deploy:deploy /app

USER deploy
WORKDIR /app

COPY --from=Builder /usr/local/bundle /usr/local/bundle
COPY --from=ClientOpsBuilder --chown=deploy:deploy /app /app
COPY --from=surnet/alpine-wkhtmltopdf:3.9-0.12.5-small /bin/wkhtmltopdf /usr/local/bin/wkhtmltopdf

ENV WKHTMLTOPDF /usr/local/bin/wkhtmltopdf
ENV RAILS_LOG_TO_STDOUT true
ENV RAILS_APPLICATION_SERVER puma

EXPOSE 8080

VOLUME /app/public

CMD [ "bundle", "exec", "rails", "server", "-b", "0.0.0.0" ]

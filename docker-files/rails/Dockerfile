ARG RUBY_VERSION=2.6.3
ARG NODE_VERSION=12

##########
#  Base  #
##########

FROM ruby:$RUBY_VERSION-alpine as base

WORKDIR /app

# Required packages only, add build packages to Builder and custom packages to final build.
# nodejs is required to load coffescript-rails and uglifier gems
RUN apk add --update --no-cache \
  imagemagick \
  nodejs \
  postgresql-client \
  tzdata \
  ttf-dejavu \
  ttf-droid \
  ttf-freefont \
  ttf-liberation \
  ttf-ubuntu-font-family \
  && rm -rf /var/cache/apk/*

COPY --from=surnet/alpine-wkhtmltopdf:3.9-0.12.5-small /bin/wkhtmltopdf /usr/local/bin/wkhtmltopdf

RUN addgroup -g 1000 -S deploy \
  && adduser -u 1000 -S deploy -G deploy \
  && mkdir -p /app && chown -R deploy:deploy /app

ENV LANG C.UTF-8
ENV RAILS_LOG_TO_STDOUT true
ENV RAILS_ROOT /app
ENV WKHTMLTOPDF /usr/local/bin/wkhtmltopdf

COPY config/database.yml.docker /app/config/database.yml

# Env defaults to production. Should be overriden in the deployment.

##################
#  Ruby Builder  #
##################

FROM base as RubyBuilder

ARG APP=clark
ARG RACK_ENV=production
ARG RAILS_ENV=production

ENV APP ${APP}
ENV DB_ADAPTER nulldb
ENV RACK_ENV ${RACK_ENV}
ENV RAILS_ENV ${RAILS_ENV}

# check that APP (brand) argument is not empty. Defaults to 'clark' in base
RUN test -n "$APP"

# Build packages only
RUN apk add --update --no-cache \
  build-base \
  git \
  linux-headers \
  postgresql-dev \
  && rm -rf /var/cache/apk/*

WORKDIR /app

COPY Gemfile* /app/
COPY gems/ /app/gems/
COPY . /app/

RUN echo "gem: --no-document" > ~/.gemrc \
  && gem install bundler \
  && bundle install --without development test --jobs 4 --retry 3 \
  && rm -rf /usr/local/bundle/cache/*.gem\
  && find /usr/local/bundle/gems/ -name "*.c" -delete \
  && find /usr/local/bundle/gems/ -name "*.o" -delete

RUN bundle exec rake assets:precompile

########################
#  Javascript Builder  #
########################
# This can be moved out of this Dockerfile once offer-rule-matrix can use external asset map.

FROM node:${NODE_VERSION}-alpine as JavascriptBuilder
ARG APP=clark
ARG APP_LOCALE
ARG DEPLOY_PREPEND
ARG LOCAL_URLS_ONLY

ARG EMBER_ENV=production
ARG NODE_ENV=production

# Keep in sync with:
# - .circleci/config.yml
ARG NODE_OPTIONS="--max-old-space-size=4096"

RUN test -n "$APP"

WORKDIR /app

COPY --from=RubyBuilder /app /app

ENV APP ${APP}
ENV APP_LOCALE ${APP_LOCALE}
ENV DEPLOY_PREPEND ${DEPLOY_PREPEND}
ENV EMBER_ENV ${EMBER_ENV}
ENV LOCAL_URLS_ONLY ${LOCAL_URLS_ONLY}
ENV NODE_ENV ${NODE_ENV}
ENV NODE_OPTIONS ${NODE_OPTIONS}

RUN apk --no-cache add \
  git

RUN npm config set unsafe-perm true
RUN yarn install --frozen-lockfile --non-interactive --prod=false

RUN cd /app/client-ops/offer-rule-matrix && yarn run build \
  && cd /app/client && yarn run build

RUN mkdir -p /app/public/assets/client-ops/@clarksource/offer-rule-matrix /app/public/assets/client && \
  cp -r /app/client-ops/offer-rule-matrix/dist/* /app/public/assets/client-ops/@clarksource/offer-rule-matrix && \
  cp -r /app/client/dist/* /app/public/assets/client

RUN rm -rf /app/node_modules \
  /app/client* \
  /app/log/* \
  /app/tmp/*


##################################
#  Build Ruby Application Image  #
##################################

FROM base

ARG APP=clark
ARG RAILS_ENV=production

ENV APP ${APP}
ENV RAILS_ENV ${RAILS_ENV}

RUN apk --no-cache add \
  file \
  libcrypto1.1 libssl1.1 \
  libgcc libstdc++ libx11 glib libxrender libxext libintl \
  vim wget gnupg htop nmap ncdu
RUN rm -rf /var/cache/apk/*

USER deploy
WORKDIR /app

COPY --from=RubyBuilder /usr/local/bundle /usr/local/bundle
COPY --from=JavascriptBuilder --chown=deploy:deploy /app /app

EXPOSE 3000

COPY docker-files/rails/entrypoint.sh /app/entrypoint.sh

CMD ["/app/entrypoint.sh"]

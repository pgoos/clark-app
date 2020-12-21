ARG BASE_VERSION=0.0.1

FROM clarksource/base_image:$BASE_VERSION

RUN apk add --update --no-cache \
  git \
  yarn \
  build-base \
  linux-headers \
  && rm -rf /var/cache/apk/* 

ENV RAILS_ENV development
ENV RACK_ENV development

RUN echo "gem: --no-document" > ~/.gemrc \
  && gem install bundler \
  && bundle install -j "$(getconf _NPROCESSORS_ONLN)" \
  && rm -rf $BUNDLE_PATH/cache/*.gem \
  && find $BUNDLE_PATH/gems/ -name "*.c" -delete \
  && find $BUNDLE_PATH/gems/ -name "*.o" -delete  

USER deploy

COPY --chown=deploy:deploy . ./

EXPOSE 3000

CMD [ "bundle", "exec", "rails", "server", "-b", "0.0.0.0" ]

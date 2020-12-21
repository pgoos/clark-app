ARG NGINX_VERSION=1.17
ARG RAILS_IMAGE_NAME

FROM ${RAILS_IMAGE_NAME} as RailsApplication

###############################
#  Web + Pre-compiled assets  #
###############################

FROM nginx:${NGINX_VERSION}-alpine

WORKDIR /app

RUN rm -rf /etc/nginx/conf.d/default.conf
# This configuration is written as a configmap using a k8t template

COPY --from=RailsApplication /app/public /app

CMD ["nginx", "-g", "daemon off;"]




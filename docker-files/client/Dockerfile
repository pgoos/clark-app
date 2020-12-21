ARG NGINX_VERSION=1.17
ARG NODE_VERSION=12
ARG RAILS_IMAGE_NAME

FROM ${RAILS_IMAGE_NAME} as RailsApplication

##############################
#  Build Ember client Image  #
##############################

FROM nginx:${NGINX_VERSION}-alpine

WORKDIR /app

RUN rm -rf /etc/nginx/conf.d/default.conf

# This configuration could be overwritten as a configmap using a k8t template
COPY docker-files/client/nginx.conf /etc/nginx/conf.d/
COPY --from=RailsApplication /app/public/assets/client/ /app/

CMD ["nginx", "-g", "daemon off;"]




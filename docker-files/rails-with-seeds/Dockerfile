ARG RAILS_IMAGE_NAME

#######################################
#  Build Ruby Application with Seeds  #
#######################################

FROM ${RAILS_IMAGE_NAME}

COPY seeds/de /app/db/seeds/de/master_data
COPY seeds/at /app/db/seeds/at/master_data
COPY seeds/shared /app/db/seeds/shared/master_data

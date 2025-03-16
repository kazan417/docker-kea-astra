#
# Define the base OS image in a single place.
#

ARG KEA_VERSION

#
# All the services basically need the same stuff so let's make a common layer.
#
FROM FROM registry.astralinux.ru/astra/ubi18 AS common
ARG DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y \
        kea-common \
    && \
    apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false \
    && apt-get clean -y && rm -rf /var/lib/apt/lists/* \
    && \
# Make sure some directories mentioned in the documentation are present and
# owned by the Kea user.

    mkdir /entrypoint.d
# As a final step we will need to run ldconfig to make sure that all the Kea
# libraries that we copied are correctly linked. This is an extra config
# file which adds a folder to the standard search locations.
#
# NOTE: The hooks folder is empty right now, to save some space, but it may be
#       populated by the user later.
RUN echo "/usr/local/lib/kea/hooks" > /etc/ld.so.conf.d/kea.conf && \
    ldconfig

# Finally we copy the common entrypoint script which will read an environment
# variable in order to later launch the correct service.
COPY entrypoint.sh /
ENTRYPOINT [ "/entrypoint.sh" ]




#
# The DHCP4 service image without any hook libraries (astra include hooks libraries anyway).
#
FROM common AS dhcp4-slim
ENV KEA_EXECUTABLE=dhcp4
ARG DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y \
        kea-dhcp4-server \
    && \
    apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false \
    && apt-get clean -y && rm -rf /var/lib/apt/lists/* 

#
# The DHCP4 service image with all relevant hooks included.
#
# The libdhcp_mysql_cb.so and libdhcp_pgsql_cb.so libraries depend on the paid
# libdhcp_cb_cmds.so library, so they are excluded.
FROM dhcp4-slim AS dhcp4
ENV KEA_EXECUTABLE=dhcp4
ARG DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y \
        kea-dhcp4-server \
    && \
    apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false \
    && apt-get clean -y && rm -rf /var/lib/apt/lists/* 


#
# The DHCP6 service image without any hook libraries.
#
FROM common AS dhcp6-slim
ENV KEA_EXECUTABLE=dhcp6
ARG DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y \
        kea-dhcp6-server \
    && \
    apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false \
    && apt-get clean -y && rm -rf /var/lib/apt/lists/* 

#
# The DHCP6 service image with all relevant hooks included.
#
# The libdhcp_mysql_cb.so and libdhcp_pgsql_cb.so libraries depend on the paid
# libdhcp_cb_cmds.so library, so they are excluded.
FROM dhcp6-slim AS dhcp6
ENV KEA_EXECUTABLE=dhcp6
ARG DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y \
        kea-dhcp6-server \
    && \
    apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false \
    && apt-get clean -y && rm -rf /var/lib/apt/lists/* 


#
# The Kea Control Agent service image.
#
FROM common AS ctrl-agent
ENV KEA_EXECUTABLE=ctrl-agent
ARG DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y \
        kea-ctrl-agent \
    && \
    apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false \
    && apt-get clean -y && rm -rf /var/lib/apt/lists/* 


#
# The Kea DHCP DDNS service image.
#
FROM common AS dhcp-ddns
ENV KEA_EXECUTABLE=dhcp-ddns
ARG DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y \
        kea-dhcp-ddns-server \
    && \
    apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false \
    && apt-get clean -y && rm -rf /var/lib/apt/lists/* 


#
# The Hooks image.
#
FROM base AS hooks
CMD [ "ls", "-ahl", "/hooks" ]

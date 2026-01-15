FROM python:3.10-slim-bookworm

WORKDIR /opt/ou

ENV LANG=C.UTF-8 \
    LC_ALL=C.UTF-8 \
    ODOO_RC=/opt/ou/odoo.cfg \
    PATH=/opt/ou/.local/bin:$PATH \
    ADDONS_PATH=/opt/ou/odoo/addons,/opt/ou/odoo/odoo/addons,/opt/ou/OpenUpgrade,/opt/ou/design-themes \
    LIST_DB=False \
    LOG_HANDLER=:INFO \
    LOG_LEVEL=info \
    PGPORT=5432

# Install build tools
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        build-essential \
        libfreetype6-dev \
        libfribidi-dev \
        libghc-zlib-dev \
        libharfbuzz-dev \
        libjpeg-dev \
        liblcms2-dev \
        libldap2-dev \
        libopenjp2-7-dev \
        libpq-dev \
        libsasl2-dev \
        libtiff5-dev \
        libwebp-dev \
        libxml2-dev \
        libxslt-dev \
        tcl-dev \
        tk-dev \
        zlib1g-dev

# Install tools
RUN apt-get install -y \ 
    curl \
    gnupg2 \
    git \
    gettext \
    jq

# Install pg client
RUN curl -SL https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add - && \
    echo "deb http://apt.postgresql.org/pub/repos/apt bookworm-pgdg main" > /etc/apt/sources.list.d/pgdg.list && \
    apt-get update && \
    apt-get install -y --no-install-recommends postgresql-client-13 && \
    rm -rf /var/lib /apt/lists/* /tmp/*

# Install tools 
RUN pip install --upgrade --no-cache-dir \
    click-odoo-contrib \
    git-aggregator

# Add odoo user
RUN groupadd -g 1000 odoo && \
    useradd -d /opt/ou -M -u 1000 -g odoo -s /bin/bash odoo && \
    chown -R odoo:odoo /opt/ou

# Switch user
USER odoo

# Copy files
COPY --chown=odoo:odoo repos.yaml odoo.cfg.tpl entrypoint.sh wait_for_pg.sh ./
RUN chmod +x entrypoint.sh wait_for_pg.sh

# Aggregate Odoo and OpenUpgrade
RUN git config --global user.email "bot@onestein.nl" && \
    git config --global user.name "Bot" && \
    gitaggregate -c repos.yaml

# Install requirements
RUN sed -i -E "s/(gevent==)21\.8\.0( ; sys_platform != 'win32' and python_version > '3.9' and python_version <= '3.10')/\122.10.2\2/;s/(greenlet==)1.1.2( ; sys_platform != 'win32' and python_version  > '3.9' and python_version <= '3.10')/\12.0.2\2/" odoo/requirements.txt && \
    pip install --no-cache-dir \
        setuptools \
        -r odoo/requirements.txt \
        -r OpenUpgrade/requirements.txt \
        -e odoo

ENTRYPOINT ["./entrypoint.sh"]

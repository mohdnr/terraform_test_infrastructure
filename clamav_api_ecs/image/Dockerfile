# Define function directory
ARG CODE_DIR="/app"

FROM tiangolo/uvicorn-gunicorn-fastapi:python3.9

RUN adduser --system --group python

RUN apt-get update && export DEBIAN_FRONTEND=noninteractive \
    && apt-get -y install --no-install-recommends ca-certificates curl git gstreamer1.0-libav libnss3-tools libatk-bridge2.0-0 libcups2-dev libxkbcommon-x11-0 libxcomposite-dev libxrandr2 libgbm-dev libgtk-3-0 libxshmfence-dev gnupg2 postgresql-client openssh-client python3-pip vim wget xz-utils zsh entr unzip clamav clamav-daemon clamdscan \
    && apt-get autoremove -y && apt-get clean -y

# Include global arg in this stage of the build
ARG CODE_DIR

WORKDIR ${CODE_DIR}

# Copy code
COPY ./app ${CODE_DIR}

RUN pip install --no-cache-dir --upgrade -r ${CODE_DIR}/requirements.txt

RUN usermod -a -G clamav python

# Setup ClamAV
RUN mkdir -p /clamav \
 && mkdir -p /tmp/clamav/quarantine \
 && rmdir /var/lib/clamav \
 && ln -s /tmp/clamav /var/lib \
 && chown -R python:python ${CODE_DIR} /clamav /tmp/clamav /var/log/clamav \
 && mv clamav_defs/* /tmp/clamav \
 && rmdir clamav_defs \ 
 && sed -i 's/User clamav/User python/g' /etc/clamav/clamd.conf \
 && sed -i 's/CompressLocalDatabase no/CompressLocalDatabase yes/g' /etc/clamav/freshclam.conf \
 && sed -i 's/DatabaseOwner clamav/DatabaseOwner python/g' /etc/clamav/freshclam.conf \
 && sed -i 's=LocalSocket /var/run/clamav/clamd.ctl=LocalSocket /tmp/clamd.sock=g' /etc/clamav/clamd.conf \ 
 && sed -i 's=LocalSocketGroup clamav=LocalSocketGroup python=g' /etc/clamav/clamd.conf \
 && sed -i 's=LocalSocketMode 666=LocalSocketMode 660=g' /etc/clamav/clamd.conf \ 
 && echo "PidFile /tmp/clamd.pid" >> /etc/clamav/clamd.conf \
 && sed -i 's=UpdateLogFile /var/log/clamav/freshclam.log=UpdateLogFile /tmp/clamav/freshclam.log=g' /etc/clamav/freshclam.conf

ENV PORT 80
EXPOSE 80
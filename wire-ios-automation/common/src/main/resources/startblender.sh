#!/bin/sh
# script to upload to new google instance
# pulls ipaddresses adn username / password from metadata
MDF="Metadata-Flavor: Google" export MDF
MDURL=http://metadata.google.internal/computeMetadata/v1/instance/ export MDURL
LOCAL_IP=`curl -s -H "${MDF}" ${MDURL}network-interfaces/0/ip`
EXTERNAL_IP=`curl -s  -H "${MDF}" ${MDURL}network-interfaces/0/access-configs/0/external-ip`
USERNAME=`curl -s  -H "${MDF}" ${MDURL}attributes/username`
PASSWORD=`curl -s  -H "${MDF}" ${MDURL}attributes/password`
cat <<EOF > /opt/etc/blender.conf
daemon                  yes
debug                   no
http_listen             0.0.0.0:8001
# prod
#backend_request_uri    https://prod-nginz-https.wire.com
#backend_event_uri      https://prod-nginz-ssl.wire.com
backend_request_uri     https://dev-nginz-https.zinfra.io
backend_event_uri       https://dev-nginz-ssl.zinfra.io
connection_accept       no
# modules
module_path             .
module                  syslog.so
module                  echo.so
#module                 mixer.so
#module                 acm.so
module                  opus.so
module                  g711.so
# syslog
syslog_facility         24
# mixer
mixer_samplerate        48000
mixer_channels          1
# opus
opus_complex            10
# streamer
streamer_srate          48000
streamer_url            http://www.rockradio1.com:8000/
EOF
/opt/bin/blender -i ${LOCAL_IP} -I ${EXTERNAL_IP}  -p ${PASSWORD} -e ${USERNAME} -f /opt/etc/blender.conf

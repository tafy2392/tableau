#!/bin/bash

DATA_DEV=${data_dev}
SERVER_URL=https://downloads.tableau.com/esdalt/2020.1.1/tableau-server-2020-1-1_amd64.deb
CLI_URL=https://downloads.tableau.com/esdalt/2020.1.1/tableau-tabcmd-2020-1-1_all.deb
DOWNLOADS=/opt/downloads/tableau
TAB_PASSWORD=${tab_password}
TAB_LIC_KEY=${tab_lic_key}
TAB_USER=${tab_user}
VHOST=${vhost}

while [ ! -e $DATA_DEV ] ; do echo "Waiting for persistent standard volume $DATA_DEV to become ready"; sleep 1 ; done
# Format $DATA_DEV if it does not contain a partition yet
if [ "$(file -b -s $DATA_DEV)" == "data" ]; then
    mkfs -L tableau-data -t ext4 $DATA_DEV
fi

mkdir -p /data
mount $DATA_DEV /data


# Persist the volume in /etc/fstab so it gets mounted again
echo "LABEL=tableau-data /data ext4 defaults,nofail 0 2" >> /etc/fstab

useradd -m -p $(openssl passwd -1 $TAB_PASSWORD) $TAB_USER
usermod -a -G adm $TAB_USER

mkdir -p $DOWNLOADS 
wget -qc -P $DOWNLOADS $SERVER_URL
wget -qc -P $DOWNLOADS $CLI_URL


cat << EOF >$DOWNLOADS/secrets
tsm_admin_user="$TAB_USER"
tsm_admin_pass="$TAB_PASSWORD"
tableau_server_admin_user="$TAB_USER"
tableau_server_admin_pass="$TAB_PASSWORD"
EOF

cat << EOF >$DOWNLOADS/config.json
{
  "configEntities": {
    "identityStore": {
      "_type": "identityStoreType",
      "type": "local"
    }
  }
}
EOF

cat << EOF >$DOWNLOADS/reg.json
{
    "country":"South Africa",
    "city":"Johannesburg",
    "last_name":"Health",
    "industry":"Health",
    "title":"Health",
    "phone":"",
    "company":"",
    "zip":"",
    "state":"",
    "department":"",
    "first_name":"",
    "email":""
}
EOF

EXTRA_OPTS=""
if [ ! -z $TAB_LIC_KEY ]; then
    EXTRA_OPTS="-k $TAB_LIC_KEY"
fi

$DOWNLOADS/automated-installer -s $DOWNLOADS/secrets \
    -f $DOWNLOADS/config.json \
    -r $DOWNLOADS/reg.json \
    -d /data/tableau \
    -a $TAB_USER \
    $EXTRA_OPTS \
    --accepteula $DOWNLOADS/tableau-server-2020-1-1_amd64.deb

apt-get update
apt-get install -y software-properties-common
add-apt-repository -y universe
add-apt-repository -y ppa:certbot/certbot
apt-get update
apt-get install -y certbot

. /etc/profile.d/tableau_server.sh

certbot certonly --standalone -d $VHOST -m letsencrypt@turn.io -n --agree-tos \
  --pre-hook "tsm stop" \
  --post-hook "tsm start && tsm security external-ssl enable --cert-file /etc/letsencrypt/live/$VHOST/fullchain.pem --key-file /etc/letsencrypt/live/$VHOST/privkey.pem && tsm pending-changes apply --ignore-prompt"

rm -rf $DOWNLOADS/secrets
rm -rf $DOWNLOADS/config.json
rm -rf $DOWNLOADS/reg.json


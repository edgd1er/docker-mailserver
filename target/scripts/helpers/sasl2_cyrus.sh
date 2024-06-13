#!/bin/bash

# Support for Postfix sasldb2 operations manager.

# It looks like the DOMAIN in below logic is being stored in /etc/postfix/vhost,
# even if it's a value used for Postfix `main.cf:mydestination`, which apparently isn't good?
# Only an issue when $myhostname is an exact match (eg: bare domain FQDN).

SASLDB2_FILE=/tmp/docker-mailserver/sasldb2


function _sasl2_cyrus_add_user() {
  local MAIL_ACCOUNT="${1}"
  local PASSWD="${2}"

  dom=$(hostname -f)
  dom=${dom#*.}
  _log 'debug' "adding sasldb2 username: ${MAIL_ACCOUNT} / password: ${PASSWD}"
  echo "${PASSWD}" | saslpasswd2 -c -p -u "$(postconf -h mydomain)" "${MAIL_ACCOUNT}"
  cp -fp /etc/sasldb2 ${SASLDB2_FILE}
  #testsaslauthd -u ${u[${i}]} -p ${p[${i}]}
}

function _sasl2_cyrus_del_user() {
  local MAIL_ACCOUNT="${1}"
  local PASSWD="${2}"
  [[ ! -e ${SASLDB2_FILE} ]] && return 0 || true

  dom=$(hostname -f)
  dom=${dom#*.}
  _log 'debug' "removing sasldb2 username: ${MAIL_ACCOUNT} / password: ${PASSWD}"
  echo "${PASSWD}" | saslpasswd2 -d -p -u "$(postconf -h mydomain)" "${MAIL_ACCOUNT}"
  cp -fp /etc/sasldb2 ${SASLDB2_FILE}
  #testsaslauthd -u ${u[${i}]} -p ${p[${i}]}
}

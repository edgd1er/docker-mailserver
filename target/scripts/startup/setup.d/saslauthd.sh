#!/bin/bash

function _setup_saslauthd() {

  __postfix__log 'trace' "Configuring SASLauthd cyrus if requested"
  gpasswd -a postfix sasl >/dev/null
  # cyrus uses a plugin not a saslauth service.
  if [[ "${SASLAUTHD_MECHANISMS,,:-''}" == cyrus ]]; then
    _log 'debug' 'Setting up SASLAUTHD for cyrus'
    CPATH="/etc/postfix/sasl"
    RCPATH="/tmp/docker-mailserver"
    CFILE="smtpd"

    #smtpd_sasl_auth_enable / smtpd_sasl_type / smtpd_sasl_path = private/auth smtpd_sasl_security_options = noanonymous, noplaintext
    #smtpd_sasl_tls_security_options = noanonymous
    __postfix__log 'trace' 'Setting up cyrus smtp auth'
    postconf -e "smtpd_sasl_auth_enable = yes"
    # Cyrus SASL configuration file name: smtpd.conf
    postconf -e "smtpd_sasl_path = ${CFILE}"
    #cyrus/dovecot auth for smtp.
    postconf -e "smtpd_sasl_type = cyrus"
    sed -i -E "s#(smtpd_sasl_type=).*#\1cyrus#g" /etc/postfix/master.cf
    #change master.cf as postconf -e is not editing it.
    #sed -i -n "s|^  -o smtpd_sasl_type=.*|^  -o smtpd_sasl_type=cyrus|g" /etc/postfix/master.cf

    # location where Cyrus SASL searches
    postconf "cyrus_sasl_config_path = ${CPATH}/${CFILE}.conf"
    #import existing users
    [[ -f ${RCPATH}/sasldb2 ]] && cp -fp ${RCPATH}/sasldb2 /etc/ || true

    __postfix__log 'trace' 'Setting up sasl auth plugin for smtpd'
    mkdir -p "${CPATH}"
    #create smtp.conf + symlink
    echo -e "pwcheck_method: auxprop\nauxprop_plugin: sasldb\nmech_list: PLAIN LOGIN CRAM-MD5 DIGEST-MD5 NTLM" >"${RCPATH}/${CFILE}.conf"
    [[ -f ${CPATH}/${CFILE}.conf ]] && rm ${CPATH}/${CFILE}.conf || true
    [[ ! -L ${CPATH}/${CFILE}.conf ]] && ln -s ${RCPATH}/${CFILE}.conf ${CPATH}/${CFILE}.conf || true
  else
    _log 'debug' 'Setting up SASLAUTHD'

    # NOTE: It's unlikely this file would already exist,
    # Unlike Dovecot/Postfix LDAP support, this file has no ENV replacement
    # nor does it copy from the DMS config volume to this internal location.
    if [[ ${ACCOUNT_PROVISIONER} == 'LDAP' ]] &&
      [[ ! -f /etc/saslauthd.conf ]]; then
      _log 'trace' 'Creating /etc/saslauthd.conf'

      # Create a config based on ENV
      sed '/^.*: $/d' >/etc/saslauthd.conf <<EOF
ldap_servers: ${SASLAUTHD_LDAP_SERVER:=${LDAP_SERVER_HOST}}
ldap_auth_method: ${SASLAUTHD_LDAP_AUTH_METHOD:=bind}
ldap_bind_dn: ${SASLAUTHD_LDAP_BIND_DN:=${LDAP_BIND_DN}}
ldap_bind_pw: ${SASLAUTHD_LDAP_PASSWORD:=${LDAP_BIND_PW}}
ldap_search_base: ${SASLAUTHD_LDAP_SEARCH_BASE:=${LDAP_SEARCH_BASE}}
ldap_filter: ${SASLAUTHD_LDAP_FILTER:=(&(uniqueIdentifier=%u)(mailEnabled=TRUE))}
ldap_start_tls: ${SASLAUTHD_LDAP_START_TLS:=no}
ldap_tls_check_peer: ${SASLAUTHD_LDAP_TLS_CHECK_PEER:=no}
ldap_tls_cacert_file: ${SASLAUTHD_LDAP_TLS_CACERT_FILE}
ldap_tls_cacert_dir: ${SASLAUTHD_LDAP_TLS_CACERT_DIR}
ldap_password_attr: ${SASLAUTHD_LDAP_PASSWORD_ATTR}
ldap_mech: ${SASLAUTHD_LDAP_MECH}
ldap_referrals: yes
log_level: 10
EOF
    fi
    sed -i \
      -e "/^[^#].*smtpd_sasl_type.*/s/^/#/g" \
      -e "/^[^#].*smtpd_sasl_path.*/s/^/#/g" \
      /etc/postfix/master.cf

    sed -i \
      -e "/smtpd_sasl_path =.*/d" \
      -e "/smtpd_sasl_type =.*/d" \
      -e "/dovecot_destination_recipient_limit =.*/d" \
      /etc/postfix/main.cf
  fi
}

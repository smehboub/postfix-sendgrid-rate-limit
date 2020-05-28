FROM centos:7

MAINTAINER Sophian Mehboub
LABEL REPO="https://github.com/smehboub/postfix-sendgrid-rate-limit"
LABEL INSPIRED_FROM_REPO="https://github.com/fametec/postfix-sendgrid"
LABEL THANKS_TO="Carlos Eduardo Fraga Ribeiro eduardo@fametec.com.br"

ENV USER postmaster@xxxxxxxxxxxxxxxxxxx

ENV PASS xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx

RUN yum -y install postfix cyrus-sasl-plain mailx epel-release

RUN curl -o /etc/yum.repos.d/Postfwd.repo https://copr.fedorainfracloud.org/coprs/nunodias/Postfwd/repo/epel-7/nunodias-Postfwd-epel-7.repo

RUN yum -y install postfwd

RUN { \
        echo '##' ; \
        echo '## Ruleset' ; \
        echo '##' ; \
        echo '##########################################################################' ; \
        echo '#Rate Limit TO: all domain - SEND_RATE_LIMIT_MAX messages in SEND_RATE_LIMIT_TIME seconds (SEND_RATE_LIMIT_TIME_MINUTES mins)' ; \
        echo 'id=R01' ; \
        echo '        recipient_domain=~/.*/' ; \
        echo "        action=rate(recipient_domain/SEND_RATE_LIMIT_MAX/SEND_RATE_LIMIT_TIME/554 4.7.1 - Sorry, exceeded SEND_RATE_LIMIT_MAX messages in SEND_RATE_LIMIT_TIME_MINUTES minutes.)" ; \
        echo '##########################################################################' ; \
        echo ; \
    } > /etc/postfwd/postfwd.cf

RUN { \
	echo ; \
	echo '# authorized networks' ; \
        echo 'mynetworks = 10.0.0.0/8, 172.16.0.0/12, 192.168.0.0/16' ; \
	echo '# postfwd config' ; \
        echo 'smtpd_recipient_restrictions = check_policy_service inet:127.0.0.1:10040' ; \
	echo ; \
	echo 'inet_interfaces = all' ; \
	echo '#Set the relayhost' ; \
	echo 'mydestination = localhost.localdomain, localhost' ; \
	echo 'relayhost = [smtp.sendgrid.net]:587' ; \
	echo 'smtp_sasl_auth_enable = yes' ; \
	echo 'smtp_sasl_password_maps = static:USER:PASS' ; \
	echo 'smtp_sasl_security_options = noanonymous' ; \
	echo ; \
	echo '# TLS support' ; \
	echo 'smtp_tls_CAfile = /etc/pki/tls/certs/ca-bundle.crt' ; \
	echo 'smtp_tls_security_level = may' ; \
	echo 'smtpd_tls_security_level = may' ; \
	echo 'smtp_tls_note_starttls_offer = yes' ; \
	echo ; \
	echo 'smtp_cname_overrides_servername=no' ; \
	echo ; \
    } >> /etc/postfix/main.cf


RUN { \
        echo '#!/bin/bash' ; \
        echo ; \
        echo 'sed -i s/SEND_RATE_LIMIT_MAX/${SEND_RATE_LIMIT_MAX:-4}/g /etc/postfwd/postfwd.cf' ; \
        echo 'sed -i s/SEND_RATE_LIMIT_TIME_MINUTES/$((${SEND_RATE_LIMIT_TIME:-1800}/60))/g /etc/postfwd/postfwd.cf' ; \
        echo 'sed -i s/SEND_RATE_LIMIT_TIME/${SEND_RATE_LIMIT_TIME:-1800}/g /etc/postfwd/postfwd.cf' ; \
        echo ; \
        echo 'source /etc/sysconfig/postfwd' ; \
        echo '/usr/sbin/postfwd \' ; \
        echo ' ${PFWARG} \' ; \
        echo ' --daemon \' ; \
        echo ' --file=${PFWCFG} \' ; \
        echo ' --interface=${PFWINET} \' ; \
        echo ' --port=${PFWPORT} \' ; \
        echo ' --user=${PFWUSER} \' ; \
        echo ' --group=${PFWGROUP} \' ; \
        echo ' --pidfile=${PFWPID} \' ; \
        echo ' -vv -L' ; \
        echo ; \
        echo 'sed -i s/USER/$USER/g /etc/postfix/main.cf' ; \
        echo 'sed -i s/PASS/$PASS/g /etc/postfix/main.cf' ; \
        echo 'postfix start' ; \
        echo ; \
        echo 'while true; do' ;\
        echo '  mailq ' ; \
        echo '  sleep 10' ; \
        echo 'done' ; \
        echo ; \
    } > /entrypoint.sh && chmod +x /entrypoint.sh


EXPOSE 25


CMD [ "/entrypoint.sh" ]

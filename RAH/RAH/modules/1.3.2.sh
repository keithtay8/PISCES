#!/bin/bash
# CIS Ubuntu 20.04
# 1.3.2 Ensure filesystem integrity is regularly checked [via Cron] (Automated);;;1.3.2: success

audit='<<AUDIT>>'
breakpoint='<<BREAKPOINT>>'
wr_p='<<WR_P>>'

if [[ ! $(grep -Prs '^(?=.*--config)(?=.*--check)([^#]+\s+)?(\/usr\/s?bin\/|^s*)aide(\.wrapper)?' /etc/cron.* /etc/crontab /var/spool/cron/) ]]; then
	if [[ ! $(grep '/usr/bin/aide.wrapper' '/var/spool/cron/crontabs/root') ]]; then
		if [[ ! -f "$(whoami).cron.backup" ]] && [[ -f "/var/spool/cron/crontabs/$(whoami)" ]]; then
			cp "/var/spool/cron/crontabs/$(whoami)" "./$(whoami).cron.backup"
			echo "'/var/spool/cron/crontabs/$(whoami)' has been backed up to './$(whoami).cron.backup'"
		fi
		$(crontab -l > mycron
		echo '0 5 * * * /usr/bin/aide.wrapper --config /etc/aide/aide.conf --check' >> mycron
		crontab mycron
		rm mycron) && echo '1.3.2: success'
	else
		echo 'An AIDE entry exists in crontab for root already, please modify this manually to:'
		echo '0 5 * * * /usr/bin/aide.wrapper --config /etc/aide/aide.conf --check'
		echo "$wr_p"
	fi || echo '1.3.2: failed'
else
	echo "$audit"
fi

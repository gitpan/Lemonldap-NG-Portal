#
# Regular cron jobs for the Lemonldap::NG portal
#
*/10 *	* * *	www-data	test -x /usr/share/lemonldap-ng/bin/purgeCentralCache

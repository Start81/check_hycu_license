# check_hycu_license
Nagios check that uses HYCU's REST API to get license status

### prerequisites

This script uses theses libs : 
REST::Client, Data::Dumper, Monitoring::Plugin, MIME::Base64, JSON, LWP::UserAgent, Readonly

to install them type :

```
sudo cpan REST::Client Data::Dumper Monitoring::Plugin MIME::Base64 JSON LWP::UserAgent Readonly
```

### Use case

```bash
check_hycu_license.pl 1.0.0

This nagios plugin is free software, and comes with ABSOLUTELY NO WARRANTY.
It may be used, redistributed and/or modified under the terms of the GNU
General Public Licence (see http://www.fsf.org/licensing/licenses/gpl.txt).

Nagios check that uses HYCUs REST API to get license status

Usage: check_hycu_license.pl -H <hostname> -p <port>  -u <User> -P <password> [-w <threshold> ] [-c <threshold> ]  [-t <timeout>] [-a <apiversion>]

 -?, --usage
   Print usage information
 -h, --help
   Print detailed help screen
 -V, --version
   Print version information
 --extra-opts=[section][@file]
   Read options from an ini file. See https://www.monitoring-plugins.org/doc/extra-opts.html
   for usage and examples.
 -H, --host=STRING
   Hostname
 -p, --port=INTEGER
  Port Number
 -a, --apiversion=string
  HYCU API version
 -u, --user=string
  User name for api authentication
 -P, --Password=string
  User name for api authentication
 -S, --ssl
   The hycu serveur use ssl
 -w, --warning=threshold in days
   See https://www.monitoring-plugins.org/doc/guidelines.html#THRESHOLDFORMAT for the threshold format.
 -c, --critical=threshold in days
   See https://www.monitoring-plugins.org/doc/guidelines.html#THRESHOLDFORMAT for the threshold format.
 -t, --timeout=INTEGER
   Seconds before plugin times out (default: 30)
 -v, --verbose
   Show details for command-line debugging (can repeat up to 3 times)
```

sample :

```bash
./check_hycu_license.pl -H MyHYCUserver --ssl -p 8443 -a v1.0 -n MyvmToBackup  -u user@domain -P password -c 100: -w 120:
```
you may get :
```bash
check_hycu_license OK - license status is VALID status message : The license is valid. | license_days_left=1641d;120:;100:d;1;2
```

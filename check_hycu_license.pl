#!/usr/bin/perl -w
#=============================================================================== 
# Script Name   : check_hycu_license.pl
# Usage Syntax  : check_hycu_license.pl -H <hostname> -p <port>  -u <User> -P <password> [-w <threshold> ] [-c <threshold> ]  [-t <timeout>] [-a <apiversion>] 
# Version       : 1.0.0
# Last Modified :15/04/2022
# Modified By   : J DESMAREST (Open Groupe)
# Description   : Nagios check that uses HYCUs REST API to get license status
# Depends On    : Net::SNMP; Monitoring::Plugin; Data::Dumper ;MIME::Base64; JSON; REST::Client; LWP::UserAgent
# 
# Changelog: 
#    Legend: 
#       [*] Informational, [!] Bugfix, [+] Added, [-] Removed 
#  - 15/04/2022| 1.0.0 | [*] First release
#===============================================================================

use strict;
use IO::Socket::SSL qw( SSL_VERIFY_NONE );
use warnings;
use Monitoring::Plugin;
use Data::Dumper;
use REST::Client;
use Data::Dumper;
use JSON;
use utf8; 
use Getopt::Long;
use MIME::Base64;
use LWP::UserAgent;
use Readonly;
use File::Basename;

Readonly our $VERSION => "1.0.0";
my $me = basename($0);
my $o_verb;
sub verb { my $t=shift; if ($o_verb) {print $t,"\n"}  ; return 0 }

my $np = Monitoring::Plugin->new(
    usage => "Usage: %s -H <hostname> -p <port>  -u <User> -P <password> [-w <threshold> ] [-c <threshold> ]  [-t <timeout>] [-a <apiversion>] \n",
    plugin => $me,
    shortname => $me,
    blurb => "$me Nagios check that uses HYCUs REST API to get license status",
    version => $VERSION,
    timeout => 30
);
$np->add_arg(
    spec => 'host|H=s',
    help => "-H, --host=STRING\n"
          . '   Hostname',
    required => 1
);
$np->add_arg(
    spec => 'port|p=i',
    help => "-p, --port=INTEGER\n"
          . '  Port Number',
    required => 1,
    default => "8443"
);
$np->add_arg(
    spec => 'apiversion|a=s',
    help => "-a, --apiversion=string\n"
          . '  HYCU API version',
    required => 1,
    default => 'v1.0'
);
$np->add_arg(
    spec => 'user|u=s',
    help => "-u, --user=string\n"
          . '  User name for api authentication',
    required => 1,
);
$np->add_arg(
    spec => 'Password|P=s',
    help => "-P, --Password=string\n"
          . '  User password for api authentication',
    required => 1,
);

$np->add_arg(
    spec => 'ssl|S',
    help => "-S, --ssl\n   The hycu serveur use ssl",
    required => 0
);
$np->add_arg(
    spec => 'warning|w=s',
    help => "-w, --warning=threshold in days\n" 
          . '   See https://www.monitoring-plugins.org/doc/guidelines.html#THRESHOLDFORMAT for the threshold format.',
);
$np->add_arg(
    spec => 'critical|c=s',
    help => "-c, --critical=threshold in days\n"  
          . '   See https://www.monitoring-plugins.org/doc/guidelines.html#THRESHOLDFORMAT for the threshold format.',
);

$np->getopts;

#Get parameters
my $o_host = $np->opts->host;
my $o_login = $np->opts->user;
my $o_pwd = $np->opts->Password;
my $o_apiversion = $np->opts->apiversion;
my $o_port = $np->opts->port;
my $o_use_ssl = 0;
$o_use_ssl = $np->opts->ssl if (defined $np->opts->ssl);
$o_verb = $np->opts->verbose;
my $o_warning = $np->opts->warning;
my $o_critical = $np->opts->critical;
my $o_timeout = $np->opts->timeout;

#Check parameters
if ($o_timeout > 60){
    $np->plugin_die("Invalid time-out");
}

#Rest client Init
my $client = REST::Client->new();
$client->setTimeout($o_timeout);
my $url = "http://";
$client->addHeader('Content-Type', 'application/json;charset=utf8');
$client->addHeader('Accept', 'application/json');
$client->addHeader('Accept-Encoding',"gzip, deflate, br");
if ($o_use_ssl) {
    my $ua = LWP::UserAgent->new(
        timeout  => $o_timeout,
        ssl_opts => {
            verify_hostname => 0,
            SSL_verify_mode => SSL_VERIFY_NONE
        },
    );
    $url = "https://";
    $client->setUseragent($ua);
}
$url = "$url$o_host:$o_port/rest/$o_apiversion/administration/license";
#Add authentication
$client->addHeader('Authorization', 'Basic ' . encode_base64("$o_login:$o_pwd"));

verb($url);
$client->GET($url);
if($client->responseCode() ne '200'){
    $np->plugin_exit('UNKNOWN', "response code : " . $client->responseCode() . " Message : Error when getting license". $client->{_res}->decoded_content );
}
my $rep = $client->{_res}->decoded_content;
my $license = from_json($rep);
verb(Dumper($license));
my $i = 0;
my @temp =();
my @criticals = ();
my @warnings = ();
my @ok = ();
my $msg;
while (exists ($license->{'entities'}->[$i])){
    my $days_left = $license->{'entities'}->[$i]->{'daysLeft'};
    #['EXPIRED', ' ALMOST_EXPIRED', ' EXCEEDED', ' VALID', ' NOT_VALID']
    my $licence_status = $license->{'entities'}->[$i]->{'status'};
    my $status_msg = $license->{'entities'}->[$i]->{'licenseStatusMsg'};
    $msg = "license status is $licence_status status message : $status_msg";
    push( @criticals, $msg) if (($licence_status eq 'EXPIRED')|| ($licence_status eq 'EXCEEDED')||($licence_status eq 'NOT_VALID'));
    push (@warnings , $msg) if ($licence_status eq 'ALMOST_EXPIRED');
    $np->add_perfdata(label => "license_days_left", value => $days_left, uom => "d", warning => $o_warning, critical => $o_critical);
    if ((defined($np->opts->warning) || defined($np->opts->critical))) {
        $np->set_thresholds(warning => $o_warning, critical => $o_critical);
        my $exit_code = $np->check_threshold($days_left);
        push( @criticals, "license days left too low") if ($exit_code == 2);
        push( @warnings, "license days left too low") if ($exit_code == 1);
    }
    $i=$i+1;
}

#Format Output
$np->plugin_exit('CRITICAL', join(', ', @criticals)) if (scalar @criticals > 0);
$np->plugin_exit('WARNING', join(', ', @warnings)) if (scalar @warnings > 0);
$np->plugin_exit('OK', $msg );

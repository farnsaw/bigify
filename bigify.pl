#!/usr/bin/perl

use DBI;
use CGI qw(:standard);
use CGI::Carp qw(fatalsToBrowser);
use Date::Calc qw(Delta_DHMS);
use Date::Parse;

my $VERSION = "v1.0";
my $cgi = new CGI;

init();
my $maxrows=40;
$maxrows = $cgi->param('maxrows') if ( $cgi->param('maxrows') > 1);
my $DEBUG = 0;
$DEBUG = $cgi->param('DEBUG') if ( $cgi->param('DEBUG') > 0);
my $show = $cgi->param('show') unless ($cgi->param('show') eq '');

unless ($action = $cgi->param('action')) { $action = "default"; }

$connected = 0;
$dbh = connectDB();

&$action;

$dbh->disconnect() if ($connected);

exit;

sub init
{
    $| = 1;

    print "Content-type: text/html\n\n";
    $FORM_ACTION = $0;
    $FORM_ACTION = substr $FORM_ACTION, (1 + rindex($FORM_ACTION, '/'));

    print qq|<html><head>|;
    print qq|<title>Random Time Generator</title>|;
    print qq|<link rel="SHORTCUT ICON" href="/img/timelock.png" type="image/png" />|;
    print qq|<link rel="stylesheet" href="/css/checkin2.css" type="text/css"></head><body>\n|;
    return();
}

sub tini
{
    print qq|</body></html>\n|;
}

sub default
{
#   checkin();
#   showCheckins();
#   showDistinctCheckins();
    listBigs();
}

sub checkin
{
  my $macAddress = $cgi->param('macAddress');
  my $reportingIP = $ENV{REMOTE_ADDR};
  my $actualIP = $cgi->param('actualIP');
  my $uname = $cgi->param('uname');
  my $uptime = $cgi->param('uptime');
  my $status = $cgi->param('status');
  my $serverURL= $cgi->param('serverURL');
  my $cpuTemp = "N/A";
     $cpuTemp = $cgi->param('cpuTemp') if ($cgi->param('cpuTemp'));

my $output  = "macAddress: '$macAddress'<br>\n";
   $output .= "reportingIP: '$reportingIP'<br>\n";
   $output .= "actualIP: '$actualIP'<br>\n";
   $output .= "uname: '$uname'<br>\n";
   $output .= "uptime: '$uptime'<br>\n";
   $output .= "status: '$status'<br>\n";
   $output .= "serverURL: '$serverURL'<br>\n";
   $output .= "cpuTemp: '$cpuTemp'<br>\n";
   $output .= "<br><hr>\n";

  my $stmt = qq|INSERT INTO checkin (macAddress, reportingIP, actualIP, uname, uptime, status, serverURL, cpuTemp) VALUES (?,?,?,?,?,?,?,?);|;
  my $rv = 0;

  $sth = $dbh->prepare($stmt);
  $rv = $sth->execute($macAddress, $reportingIP, $actualIP, $uname, $uptime, $status, $serverURL, $cpuTemp);
   $output .= "rv: $rv<br>\n";
  $output .= $dbh->errstr . "\n";
  print $output;
  logwrite('checkin:', $output);
  $sth->finish();
return();
}

sub createCheckinTable
{
  my $stmt = qq|CREATE TABLE checkin (
	id INT NOT NULL AUTO_INCREMENT, 
	macAddress varchar(20),
	reportingIP varchar(50),
	actualIP varchar(50),
	uname varchar(255),
	uptime varchar(200),
	status varchar(255),
	serverURL varchar(255),
	cpuTemp varchar(255),
    PRIMARY KEY ( id )
	);
	|;

  my $rv = 0;

  $sth = $dbh->prepare($stmt);
  $rv = $sth->execute();
  $output .= "rv: $rv<br>\n";
  $output .= $dbh->errstr . "\n";
  print $output;
  logwrite('checkin:', $output);
  $sth->finish();
  return();
}

sub createBigifyTable
{
  my $stmt = qq|CREATE TABLE bigify (
    id INT NOT NULL AUTO_INCREMENT, 
    version float,
    name varchar(1024),
    description varchar(1024),
    code varchar(1024),
    url varchar(1024),
    state varchar(1024),
    date_created date,
    date_modified date,
    PRIMARY KEY ( id )
	);
	|;

  my $rv = 0;

  $sth = $dbh->prepare($stmt);
  $rv = $sth->execute();
  $output .= "rv: $rv<br>\n";
  $output .= $dbh->errstr . "\n";
  print $output;
  logwrite('createBigifyTable:', $output);
  $sth->finish();
  return();
}

sub listBigs
{
  my $reportingIP = $ENV{REMOTE_ADDR};
  my $actualIP = $cgi->param('actualIP');
  my $uname = $cgi->param('uname');
  my $uptime = $cgi->param('uptime');
  my $serverURL= $cgi->param('serverURL');

my $output  = "<br>\n";
   $output .= "<br><hr>\n";

  my $stmt = qq|select id, version, name, description, code, url, state, date_created, date_modified from bigify;|;
  my $rv = 0;

  $sth = $dbh->prepare($stmt);
  $rv = $sth->execute();
  logwrite('listBigs : rv', $rv);
  logwrite('listBigs : dbh->errstr', $dbh->errstr);

  my $rowcount = 1;

  my $output = qq|<div class="piCheckins"><table>\n|;
	$output .= "<tr><th>id</th><th>version</th><th>name</th><th>Description</th><th>Code</th><th>URL</th><th>state</th><th>date_created</th><th>date_modified</th></tr>\n";
  while ($row = $sth2->fetchrow_hashref())
  {
	$output .= "<tr>";
	$output .= "<td>" . $row->{'id'} . "</td>";
	$output .= "<td>" . $row->{'version'} . "</td>";
	$output .= "<td>" . $row->{'name'} . "</td>";
	$output .= "<td>" . $row->{'description'} . "</td>";
	$output .= "<td>" . $row->{'code'} . "</td>";
	$output .= "<td>" . $row->{'url'} . "</td>";
	$output .= "<td>" . $row->{'state'} . "</td>";
	$output .= "<td>" . $row->{'date_created'} . "</td>";
	$output .= "<td>" . $row->{'date_modified'} . "</td>";
	$output .= "</tr>\n";
	last if ($rowcount++ >= $maxrows);
  }
  $timeUpdated = scalar localtime();
  $output .= qq|<tr><td colspan="9">$timeUpdated</td></tr>|;
  $output .= "</table>\n";
  print "<hr>$output<br>\n";
  $sth2->finish();
  return();

  $sth->finish();
  return();
}

sub showCheckins
{

  $stmt = qq|select id, macAddress, reportingIP, actualIP, CONVERT_TZ(reportingTime,'US/Central','US/Eastern') as reportingTime, uname, uptime, status, serverURL, cpuTemp from checkin order by id desc|;
  $sth2 = $dbh->prepare($stmt);
  $rv = $sth2->execute();
#print "rv: $rv<br>\n";

my $rowcount = 1;

  my $output = qq|<div class="piCheckins"><table>\n|;
	$output .= "<tr><th>id</th><th>macAddress</th><th>reportingIP</th><th>actualIP</th><th>reporting Time</th><th>uname</th><th>uptime</th><th>status</th><th>serverURL</th><th>cpuTemp</th></tr>\n";
  while ($row = $sth2->fetchrow_hashref())
  {
	$output .= "<tr>";
	$output .= "<td>" . $row->{'id'} . "</td>";
	$output .= "<td>" . $row->{'macAddress'} . "</td>";
	$output .= "<td>" . $row->{'reportingIP'} . "</td>";
	$output .= "<td>" . $row->{'actualIP'} . "</td>";
	$output .= "<td>" . $row->{'reportingTime'} . "</td>";
	$output .= "<td>" . $row->{'uname'} . "</td>";
	$output .= "<td>" . $row->{'uptime'} . "</td>";
	$output .= "<td>" . $row->{'status'} . "</td>";
	$output .= "<td>" . $row->{'serverURL'} . "</td>";
	$output .= "<td>" . $row->{'cpuTemp'} . "</td>";
	$output .= "</tr>\n";
	last if ($rowcount++ >= $maxrows);
  }
  $timeUpdated = scalar localtime();
  $output .= qq|<tr><td colspan="9">$timeUpdated</td></tr>|;
  $output .= "</table>\n";
print "<hr>$output<br>\n";
  $sth2->finish();
  return();
}

sub showDistinctCheckins
{
  my $rip = '64.138.236.194';
     $rip = '185.75.3.213' if ($show eq 'cc');
     $rip = '98.117.64.207' if ($show eq 'hci');

  my $stmt = qq|select distinct(macAddress) from checkin order by uname|;
#  my $stmt = qq|select distinct(macAddress) from macaddresses|;
  my $sth = $dbh->prepare($stmt);
  my $rv = $sth->execute();
  my $stateImage = "/img/OK.jpg";
  my $rowcount = 0;

  while ($row = $sth->fetchrow_hashref())
  {
    push @macAddresses, $row->{'macAddress'};
  }
  $sth->finish();

  $stmt = qq|select id, macAddress, reportingIP, actualIP, CONVERT_TZ(reportingTime,'US/Central','US/Eastern') as reportingTime, uname, uptime, status, serverURL, cpuTemp from checkin where macAddress = ? AND reportingIP = ? order by id desc|;
  $stmt = qq|select id, macAddress, reportingIP, actualIP, CONVERT_TZ(reportingTime,'US/Central','US/Eastern') as reportingTime, uname, uptime, status, serverURL, cpuTemp from checkin where macAddress = ? order by id desc| if ($show eq 'all');
  $sth2 = $dbh->prepare($stmt);

  my $rowcount = 1;
  my $output = qq|<script src="/js/zclip/ZeroClipboard.js"></script>\n|;
  $output .= qq|<div class="piCheckins"><table>\n|;
  $output .= "<tr><th>State</th><th>id</th><th>macAddress</th><th>reportingIP</th><th>actualIP</th><th>reporting Time</th><th>uname</th><th>uptime</th><th>status</th><th>serverURL</th><th>cpuTemp</th></tr>\n";
  foreach $macAddress (@macAddresses)
  {
	$rowcount++;
	$stateImage = "/img/OK.jpg";
	if ($show eq 'all') {
        	$rv = $sth2->execute($macAddress);
	}else{
        	$rv = $sth2->execute($macAddress, $rip);
	}
        $row = $sth2->fetchrow_hashref();

        #print "rv: $rv<br>\n";
	my $style = "";
next unless ($row->{'id'});
	if (badState($row))
	{
		$style = 'style="background-color: #ff5500; important!"';
		$stateImage = "/img/error.jpg";
	}

	$output .= "<tr $style>";
	$output .= qq|<td><img src="$stateImage" width="28" height="32"></td>|;
	$output .= "<td>" . $row->{'id'} . "</td>";
	$output .= "<td>" . $row->{'macAddress'} . "</td>";
	$output .= "<td>" . $row->{'reportingIP'} . "</td>";
	$output .= qq|<td><button id="copy-button-$rowcount" data-clipboard-text="| . $row->{'actualIP'} . qq|" title="| . $row->{'actualIP'} . qq|">| . $row->{'actualIP'} . "</button></td>";
	$output .= "<td>" . $row->{'reportingTime'} . "</td>";
	$output .= "<td>" . $row->{'uname'} . "</td>";
	$output .= "<td>" . $row->{'uptime'} . "</td>";
	$output .= "<td>" . $row->{'status'} . "</td>";
	$output .= "<td><a href='" . $row->{'serverURL'} . "'>" . $row->{'serverURL'} . "</a></td>";
	$output .= "<td>" . $row->{'cpuTemp'} . "</td>";
	$output .= "</tr>\n";
  }
  $timeUpdated = scalar localtime(time+3600);
  $output .= qq|<tr><th colspan="11">$timeUpdated</th></tr>|;
  $output .= "</table>\n";
  $output .=qq|<script>\n|;
for (my $i=1; $i <= $rowcount; $i++)
{
  $output .=qq|
var client_$i = new ZeroClipboard( document.getElementById("copy-button-$i") );

client_$i.on( "ready", function( readyEvent ) {
  // alert( "ZeroClipboard SWF is ready!" );

  client_$i.on( "aftercopy", function( event ) {
    // `this` === `client`
    // `event.target` === the element that was clicked
//    event.target.style.display = "none";
//    alert("Copied text to clipboard: " + event.data["text/plain"] );
  } );
} );
|;
}
$output .= qq|</script>\n|;

  print "<hr>\n" if ($DEBUG);
  print "$output<br>\n";
$sth2->finish();
  return();
}

sub badState
{
  my ($row) = @_;
  my $badState = 0;
  $badState = tooOld($row->{'reportingTime'});
  $badState = checkStatus($row->{'status'}) unless($badState);
#  $badState = checkServerURL($row->{'serverURL'}) unless($badState);
  return($badState);
}

sub tooOld
{
  my ($rt) = @_;
  my $timestamp = time() + 3600;
#  print "timestamp: $timestamp<br>\n";
  my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime($timestamp);
  my ($rtsec, $rtmin, $rthour, $rtday, $rtmonth, $rtyear, $zone) =  strptime($rt);
  $mon ++;
  $rtmonth++;
  $year += 1900;
  $rtyear += 1900;
  my $tooOld = 0;
#  $hour +=1;
#  if ($hour > 23)
#  {
#    $hour = $hour - 24;
#    $mday++;
#  }

unless (1 && ($rt))
{
print "rt: $rt<br>\n";
print "reportingTime breakdown:($rtyear, $rtmonth, $rtday, $rthour, $rtmin, $rtsec)<br>\n"; 
print "Current Time breakdown: ($year, $mon, $mday, $hour, $min, $sec)<br>\n"; 
}
  return (1) unless ($rt);

($ddays, $dhours, $dminutes, $dseconds) =
  Delta_DHMS( $rtyear, $rtmonth, $rtday, $rthour, $rtmin, $rtsec,  # earlier
              $year, $mon, $mday, $hour, $min, $sec); # later

if ($DEBUG)
{
print "rt: $rt<br>\n";
print "($rtyear, $rtmonth, $rtday, $rthour, $rtmin, $rtsec)<br>\n"; 
print "($year, $mon, $mday, $hour, $min, $sec)<br>\n"; 
print "($ddays, $dhours, $dminutes, $dseconds)<br><hr>\n"; 
}

  $tooOld = 0 if (rand(3) >=2);

  if (($dminutes > 20) || $ddays || $dhours)
  {
    $tooOld = 1;
  }
  return($tooOld);
}

sub checkStatus
{
  my ($status) = @_;
  my $checkStatus = 0;

  unless ($status =~ /Status: Server Accessible/)
  {
    $checkStatus = 1;
  }

  return($checkStatus);
}

sub checkServerURL
{
  my ($serverURL) = @_;
  my $checkServerURL = 0;

  unless ($serverURL =~ /http:..gmh-displayprod.ORDisplay.Home/)
  {
    $checkServerURL = 1;
  }

  return($checkServerURL);
}

sub show_env
{
	$user = `whoami`;
	print "user = $user<br>\n";
	print qq|<TABLE>\n|;
	print qq|<TR><TH>Variable</TH><TH>Value</TH></TR>\n|;
	foreach $key (keys %ENV)
	{
		print qq|<tr><td>$key</td><td>$ENV{$key}</td></tr>\n|;
	}
	print qq|</TABLE>\n|;

	return();
}

sub show_params
{
	print qq|<TABLE border="1">\n|;
	print qq|<TR><TH>CGI Parameter</TH><TH>Value</TH></TR>\n|;
	foreach $key ($cgi->param)
	{
		print qq|<tr><td>$key</td><td>|, $cgi->param($key), qq|</td></tr>\n|;
	}
	print qq|</TABLE>\n|;

	return();

}

sub connectDB
{
	my $dbh;
	unless ($connected)
	{
		$dbh = DBI->connect("dbi:mysql:dbname=hci", "farnsaw", "rthese3") || die "DB Connection Failed: ", $DBI::errstr, "\n\n";
		$connected = 1;
	}

	return($dbh);
}

sub logwrite
{
  my $logfilename = "/var/cgi-logs/checkin.pl.log";
  my $logfilename = "/tmp/checkin.pl.log";
  my @lines = @_;
  return() unless ($DEBUG);
  chomp @lines;
  open LOGFILE, ">>$logfilename" or print "ERROR: Could not write to log file $logfilename";
  print LOGFILE (join "\n", @lines) . "\n";
  close LOGFILE;
}

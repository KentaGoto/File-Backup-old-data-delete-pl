use strict;
use warnings;
use utf8;
use File::Copy 'copy';
use Email::MIME;
use Email::Sender::Simple qw(sendmail);
use Email::Sender::Transport::SMTP::TLS;
use MIME::Lite;
use Encode qw(encode);
use File::Path 'rmtree';

my $time = time();
my $offset = 60 * 60 * 24 * 7; # 7 days a go

my ( $sec, $min, $hour, $mday, $month, $year, $wday, $isdst ) =
  localtime( $time - $offset );

# Offset
my $offset_date = sprintf("%04d%02d%02d",$year+1900,$month+1,$mday);

# The folder to be deleted
my $dir = '//hoge\\Backups';
my @ll_dir = glob "$dir/*";

# Deletion process
my @deleted;
foreach my $folder (@ll_dir){
	my $folder_yymmdd = $folder;
	$folder_yymmdd =~ s{^.+/(\d+)$}{$1};           # Folder name only
	$folder_yymmdd = substr($folder_yymmdd, 0, 8); # Year and month to date only

	# Remove if it was more than a week before the current
	if ( $folder_yymmdd <= $offset_date  ){
		$folder =~ s{\/}{\\}g;
		push (@deleted, $folder);
		rmtree $folder;
	}
}

&sendMail("[ESRI] Old trackingsheet delete", \@deleted);

# Mail
sub sendMail {
	my ($send_subject, $send_body) = @_;
	
	my $send_from    = '<FROM>';
	my $send_to      = '<TO>';
	my $send_cc      = '<Cc>';

	my $msg = MIME::Lite->new (
		From => $send_from,
		To => $send_to,
		Cc => $send_cc,
		Subject => encode( 'MIME-Header', $send_subject ),
		Type =>'multipart/mixed'
	);

	$msg->attach (
		Type => 'TEXT',
		Data => Encode::encode( 'utf8', $send_body )
	);
	
	MIME::Lite->send( 'smtp', '<DOMAIN>', Timeout=>60, AuthUser=>'<USER>', AuthPass=>'<PASSWORD>' );
	$msg->send;
}

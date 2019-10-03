package CGI::Github::Webhook;
 
# ABSTRACT: Easily create CGI based GitHub webhooks
 
use strict;
use warnings;
use 5.010;
 
our $VERSION = '0.06'; # VERSION
 
use Moo;
use CGI;
use Data::Dumper;
use JSON;
use Try::Tiny;
use Digest::SHA qw(hmac_sha1_hex);
use File::ShareDir qw(module_dir);
use File::Copy;
use File::Basename;
 
 
#=head1 EXPORT
#
#A list of functions that can be exported.  You can delete this section
#if you don't export anything, such as for a purely object-oriented module.
 
 
has badges_from => (
    is => 'rw',
    default => sub { module_dir(__PACKAGE__); },
    isa => sub {
        die "$_[0] needs to be an existing directory"
            unless -d $_[0];
    },
    lazy => 1,
    );
 
 
has badge_to => (
    is => 'rw',
    default => sub { return },
    isa => sub {
        die "$_[0] needs have a file suffix"
            if (defined($_[0]) and $_[0] !~ /\./);
    },
    );
 
 
has cgi => (
    is => 'ro',
    default => sub { CGI->new() },
    );
 
 
has log => (
    is => 'ro',
    default => sub { '/dev/stderr' },
    isa => sub {
        my $dir = dirname($_[0]);
        die "$dir doesn't exist!" unless -d $dir;
    },
    );
 
 
has mime_type => (
    is => 'ro',
    default => sub { 'text/plain; charset=utf-8' },
    );
 
 
has secret => (
    is => 'ro',
    required => 1,
    );
 
 
has text_on_success => (
    is => 'rw',
    default => sub { 'Successfully triggered' },
    );
 
 
has text_on_auth_fail => (
    is => 'rw',
    default => sub { 'Authentication failed' },
    );
 
 
has text_on_trigger_fail => (
    is => 'rw',
    default => sub { 'Trigger failed' },
    );
 
 
 
has trigger => (
    is => 'rw',
    required => 1,
);
 
 
has trigger_backgrounded => (
    is => 'rw',
    default => 1,
);
 
 
has authenticated => (
    is => 'lazy',
    );
 
sub _build_authenticated {
    my $self = shift;
 
    my $logfile = $self->log;
    my $q       = $self->cgi;
    my $secret  = $self->secret;
 
    open(my $logfh, '>>', $logfile);
    say $logfh "Date: ".localtime;
    say $logfh "Remote IP: ".$q->remote_host()." (".$q->remote_addr().")";
 
    my $x_hub_signature =
        $q->http('X-Hub-Signature') || '<no-x-hub-signature>';
    my $calculated_signature = 'sha1='.
        hmac_sha1_hex($self->payload // '', $secret);
 
    print $logfh Dumper($self->payload_perl,
                        $x_hub_signature, $calculated_signature);
    close $logfh;
 
    return $x_hub_signature eq $calculated_signature;
}
 
 
has payload => (
    is => 'lazy',
    );
 
sub _build_payload {
    my $self = shift;
    my $q    = $self->cgi;
 
    if ($q->param('POSTDATA')) {
        return ''.$q->param('POSTDATA');
    } else {
        return;
    }
}
 
 
has payload_json => (
    is => 'lazy',
    );
 
sub _build_payload_json {
    my $self = shift;
    my $q    = $self->cgi;
 
    my $payload = qq({"payload":"none"});
    if ($self->payload) {
        $payload = $self->payload;
        try {
            decode_json($payload);
        } catch {
            s/\"/\'/g; s/\n/ /gs;
            $payload = qq({"error":"$_"});
        };
    }
 
    return $payload;
}
 
 
has payload_perl => (
    is => 'lazy',
    );
 
sub _build_payload_perl {
    my $self = shift;
 
    return decode_json($self->payload_json);
}
 
 
sub deploy_badge {
    my $self = shift;
    return unless $self->badge_to;
 
    my $basename = shift;
    die "No basename provided" unless defined($basename);
 
    my $suffix = $self->badge_to;
    $suffix =~ s/^.*(\.[^.]*?)$/$1/;
    my $badge = $self->badges_from.'/'.$basename.$suffix;
 
    my $logfile = $self->log;
    open(my $logfh, '>>', $logfile);
 
    my $file_copied = copy($badge, $self->badge_to);
    if ($file_copied) {
        say $logfh "$badge successfully copied to ".$self->badge_to;
        return 1;
    } else {
        say $logfh "Couldn't copy $badge  to ".$self->badge_to.": $!";
        return;
    }
}
 
 
sub header {
    my $self = shift;
    if (@_) {
        return $self->cgi->header(@_);
    } else {
        return $self->cgi->header($self->mime_type);
    }
}
 
 
sub send_header {
    my $self = shift;
 
    print $self->header(@_);
}
 
 
sub run {
    local $| = 1;
    my $self = shift;
 
    $self->send_header();
 
    my $logfile = $self->log;
    open(my $logfh, '>>', $logfile);
 
    if ($self->authenticated) {
        my $trigger = $self->trigger.' >> '.$logfile.' 2>&1 '.
            ($self->trigger_backgrounded ? '&' : '');
        my $rc = system($trigger);
        if ($rc != 0) {
            say $logfh $trigger;
            say $self->text_on_trigger_fail;
            say $logfh $self->text_on_trigger_fail;
            if ($? == -1) {
                say $logfh "Trigger failed to execute: $!";
                $self->deploy_badge('errored');
            } elsif ($? & 127) {
                printf $logfh "child died with signal %d, %s coredump\n",
                ($? & 127),  ($? & 128) ? 'with' : 'without';
                $self->deploy_badge('errored');
            } else {
                printf $logfh "child exited with value %d\n", $? >> 8;
                $self->deploy_badge('failed');
            }
            close $logfh;
            return 0;
        } else {
            $self->deploy_badge('success');
            say $self->text_on_success;
            say $logfh $self->text_on_success;
 
            close $logfh;
            return 1;
        }
    } else {
        say $self->text_on_auth_fail;
        say $logfh $self->text_on_auth_fail;
        close $logfh;
        return; # undef or empty list, i.e. false
    }
}
 
 
1; # End of CGI::Github::Webhook
 
__END__
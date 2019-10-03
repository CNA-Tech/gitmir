#!/usr/bin/perl
 
use CGI::Github::Webhook;
 
my $ghwh = CGI::Github::Webhook->new(
    mime_type => 'text/plain',
    trigger => 'echo "the trigger ran"',
    trigger_backgrounded => 0,
    secret => 'noodles',
    log => '/tmp/trigger.log',
    ...
);
$ghwh->run();
#!/usr/bin/env perl

use strict;
use warnings;
use Fcntl qw(:flock);

my ($name, $address, undef, $tags) = split("\t", <STDIN>);
my $event = $ENV{SERF_EVENT};
my $file  = "/etc/munin/conf.d/${name}.conf";

chomp $tags;
my @tags_group = split(/,/, $tags);
my ($group) = map /^munin_group=(.+)/, @tags_group or die 'unknown tag';
$group =~ s/^munin_group=//;

if ($event eq 'member-join') {
    open my $fh, "> ${file}" or die $!;
    flock($fh, LOCK_EX);

    print $fh <<CONF;
[${group};${name}]
    address ${address}
    use_node_name yes
CONF

    flock($fh, LOCK_UN);
    close $fh;
}
elsif (
    $event eq 'member-leave' ||
    $event eq 'member-failed'
) {
    unlink $file;
}

#!/usr/bin/env perl

use strict;
use warnings;
use Fcntl qw(:flock);

my ($hostname, $address, $role, $tags) = split(/\t/, <STDIN>);
my $event = $ENV{SERF_EVENT};
my $file  = "/etc/munin/conf.d/${hostname}.conf";

my @tag_groups  = split(/,/, $tags);
my @munin_group = grep /^munin_group=/, @tag_groups;
my $group = $munin_group[0];
$group =~ s/^munin_group=//;
chomp $group;

if ($event eq 'member-join') {
    open my $fh, "> ${file}" or die $!;
    flock($fh, LOCK_EX);

    print $fh <<CONF;
[${group};${hostname}]
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
#!/usr/bin/env perl

use strict;
use warnings;
use Fcntl qw(:flock);

while (<STDIN>) {
    chomp;
    my @member_fields = split("\t", $_, -1);
    die "fields must include 4 elements" unless @member_fields == 4;
    my ($name, $address, undef, $tags) = @member_fields;

    my $event = $ENV{SERF_EVENT};
    my $file  = "/etc/munin/conf.d/${name}.conf";

    my @tags_group = split(/,/, $tags);
    my ($group) = map /^munin_group=(.+)/, @tags_group or die 'munin_group is nowhere';
    $group =~ s/^munin_group=//;

    if (
        $event eq 'member-join' ||
        $event eq 'member-update'
    ) {
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
    elsif ( $event eq 'member-leave' ) {
        unlink $file;
    }
}

__END__

=head1 NAME

serf-munin.pl

=head1 SYNOPSIS

This serf event-handler automatically generates config files of munin-node.

=head1 REQUIREMENT

=over 3

=item 1. serf

=item 2. munin_group tag of serf

=back

=head1 Sample tag

=begin text

    {
      "tags": {
        "munin_group": "app"
      }
    }

=end text

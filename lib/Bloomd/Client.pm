package Bloomd::Client;

use strict;
use warnings;
our $VERSION = '0.01';
use IO::Socket::INET;

sub new {
    my ($class, %args) = @_;

    $args{server} ||= 'localhost:26006';
    my $sock = IO::Socket::INET->new(
        PeerAddr => $args{server},
        Proto => 'tcp'
    )
        or die "Can't connect to @{[ $args{server} ]}";
    $args{sock} = $sock;
    bless \%args, $class;
}

sub set {
    my ($self, $key) = @_;
    $self->set_multi($key);
}

sub set_multi {
    my ($self, @keys) = @_;

    my $key = join "\t", @keys;
    my $sock = $self->{sock};
    print $sock "set $key\r\n"
        or die "Can't write sock: $!";

    my $line = <$sock>;
    die "Can't read sock: $!" unless defined $line;

    if ( $line eq "OK\r\n" ) {
        return 1;
    } else {
        return 0;
    }
}

sub check_multi {
    my ($self, @keys) = @_;

    my $key = join "\t", @keys;
    my $sock = $self->{sock};
    print $sock "check $key\r\n"
        or die "Can't write sock: $!";

    my $result = {};
    while ( my $line = <$sock> ) {
        if ( $line eq "END\r\n" ) {
            return $result;
        } else {
            if ( $line =~ /^CHECK (\S+) (\d)\r\n/ ) {
                $result->{$1} = $2;
            }
        }
    }
    die "Can't read sock: $!";
}

sub check {
    my ($self, $key) = @_;
    my $result = $self->check_multi($key);
    return $result->{$key};
}

sub DESTROY {
    my ($self, ) = @_;
    close $self->{sock};
}

1;
__END__

=head1 NAME

Bloomd::Client -

=head1 SYNOPSIS

  use Bloomd::Client;
  my $client = Bloomd::Client->new(server => "localhost:26006");
  $client->set("hoge");
  $client->check("hoge") #=> 1 # may be.
  $client->check("bar") #=> 0

=head1 DESCRIPTION

Bloomd::Client is

=head1 AUTHOR

Keiji Yoshimi E<lt>walf443 at gmail dot comE<gt>

=head1 SEE ALSO

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

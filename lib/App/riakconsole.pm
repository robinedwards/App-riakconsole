use 5.010;
use MooseX::Declare;

class App::riakconsole  {
    use Net::RiakPB;
    use Term::ReadLine;
    use MooseX::MultiMethods;
    use MooseX::Types::Moose qw/Str Int/;

    with 'MooseX::Getopt::Dashes';

    our $VERSION = 0.001;
   
    has hostname => (
        is => 'rw',
        isa => Str,
        required => 1,
    );

    has port => (
        is => 'rw',
        isa => Int,
        required => 1,
    );

    has client => (
        is => 'rw',
        isa => 'Net::RiakPB',
        traits => ['NoGetopt']
    );

    method BUILD {
        say "Connecting to ". $self->hostname.":".$self->port.".."; 

        $self->client(
            Net::RiakPB->new(
                hostname => $self->hostname,
                port => $self->port
            )
        );
    }

    method run {
        say __PACKAGE__ ." v". $App::riakconsole::VERSION;

        my $term = Term::ReadLine->new('Riak Console');

        while (my $cmd = $term->readline('riak: ')) {
            $term->addhistory($cmd);

            $cmd =~ s/^\s+//g;
            $cmd =~ s/\s+$//g;

            my ($cmd, @args) = split /\s+/, $cmd;

            $self->dispatch($cmd, \@args);
        }
    }

    method dispatch (Str $cmd, ArrayRef $args) {
        my $cmd_method = "cmd_$cmd";
        say "error unknown command: $cmd" unless $self->can($cmd_method);
        $self->$cmd_method(@$args);
    }

    multi method cmd_ls (Str $bucket_name) {
        my $bucket = $self->client->bucket($bucket_name);         
        say $_ for $bucket->get_keys;
    }

    multi method cmd_ls {
        say $_ for (@{$self->client->all_buckets});
    }

    method cmd_size (Str $bucket_name) {
        my $bucket = $self->client->bucket($bucket_name);         
        say scalar($bucket->get_keys);
    }
}

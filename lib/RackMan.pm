package RackMan;

use Moose;
use Term::ANSIColor qw< :constants >;
use namespace::autoclean;


our $VERSION = "1.14";
our $STATUS  = 0;
$::COMMAND ||= __PACKAGE__;


has config => (
    is => "ro",
    isa => "RackMan::Config",
    default => sub {
        require RackMan::Config;
        RackMan::Config->new(-file => "/etc/rack.conf")
    },
);

has options => (
    is => "ro",
    isa => "HashRef",
);

has racktables => (
    is => "ro",
    isa => "RackTables::Schema",
    lazy => 1,
    builder => "connection",
);


#
# connection()
# ----------
sub connection {
    my $self = shift;

    # check that the connection parameters are correctly set
    my @params = $self->config->val(database => "dsn")
        or RackMan->error("[database]/dsn is missing from the config file");

    push @params, map {
        my $value = $self->config->val(database => $_);
        defined $value ? $value
        : RackMan->error("[database]/$_ is missing from the config file")
    } qw< user password >;

    require RackTables::Schema;
    return RackTables::Schema->connect(@params)
}


#
# device_by_id()
# ------------
sub device_by_id {
    my ($self, $id) = @_;

    require RackMan::Device;
    return RackMan::Device->new({
        id => $id,  rackman => $self,
        racktables => $self->racktables,
    })
}


#
# device_by_name()
# --------------
sub device_by_name {
    my ($self, $name) = @_;

    require RackMan::Device;
    return RackMan::Device->new({
        name => $name,  rackman => $self,
        racktables => $self->racktables,
    })
}


#
# device()
# ------
*device = \&device_by_name;


#
# process()
# -------
sub process {
    my ($self, $action, @args) = @_;

    my %opts;
    my @rest;

    # parse task options
    while (my $arg = shift @args) {
        if ($arg eq "as") {
            $opts{$arg} = shift @args;
        }
        else {
            push @rest, $arg;
        }
    }

    my $name = pop @rest;
    my $method = "task_$action";

    require RackMan::Tasks;

    RackMan->error("unknown action '$action'")
        unless RackMan::Tasks->meta->has_method($method);

    if ($action eq "list") {
        RackMan::Tasks->$method({ rackman => $self, stdout => 1,
            type => $name, %opts });
    }
    else {
        my $object = $self->device($name);
        $self->config->set_current_rackobject($object);
        RackMan::Tasks->meta->apply($object);
        $object->$method({ rackman => $self, stdout => 1, %opts });
    }
}


#
# get_scm()
# -------
sub get_scm {
    my ($self, $args) = @_;

    my $type = "none";
    my $caller = caller();

    if ($self->options->{scm}) {
        # global default SCM tool
        my $default = $self->config->val(general => "default_scm", "none");

        # check if the caller has its own configuration section
        if ($caller->can("CONFIG_SECTION")) {
            my $section = $caller->CONFIG_SECTION;
            $type = $self->config->val($section, "scm", $default);
        }
    }

    # clean leading and trailing spaces
    $type =~ s/^ +| +$//g;

    require RackMan::SCM;
    return RackMan::SCM->new({ type => $type, %$args,
        verbose => $self->options->{verbose}, prefix => "    x " })
}


#
# warning()
# -------
sub warning {
    my $class = shift;
    warn "$::COMMAND: ", BOLD(YELLOW("warning: ")), @_, "\n";
}


#
# error()
# -----
sub error {
    my $class = shift;
    warn "$::COMMAND: ", BOLD(RED("error: ")), @_, "\n";
    exit ($STATUS || 1);
}


#
# error_n()
# -------
sub error_n {
    print STDERR "\n";
    goto &error;
}


#
# status()
# ------
sub status {
    return $STATUS
}


#
# set_status()
# ----------
sub set_status {
    $STATUS = $_[1];
}


__PACKAGE__->meta->make_immutable;

__END__

=pod

=head1 NAME

RackMan - Main backend module

=head1 SYNOPSIS

    use RackMan;
    use RackMan::Config;

    my $config  = RackMan::Config->new(-file => "/etc/rack.conf");
    my $rackman = RackMan->new({ config => $config });


=head1 DESCRIPTION

This module provides a simple interface to access and fetch information
about RackObjects from the RackTables database.


=head1 METHODS

=head2 connection

Connect to the RackTables database using the parameters from the
configuration file.


=head2 device

Alias for C<device_by_name()>.


=head2 device_by_id

Try to find and return the RackObject with the given ID.


=head2 device_by_name

Try to find and return the RackObject with the given name.


=head2 get_scm

Return a RackMan::SCM object corresponding to the tool selected by the
configuration file and command line options.


=head2 process

Process and execute an action as given from the command line.

Arguments are expected to be:

=over

=item *

the action name

=item *

optional action options, as a plain hash

=item *

RackObject name

=back


=head2 error

Class method to print an error and exit.


=head2 error_n

Class method to print an error, preceded by a newline, and exit.


=head2 set_status

Class method to set the return status of the program.


=head2 status

Class method to get the return status of the program.


=head2 warning

Class method to print a warning.


=head1 AUTHOR

Sebastien Aperghis-Tramoni (sebastien@aperghis.net)

=cut


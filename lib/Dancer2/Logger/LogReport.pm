# This code is part of distribution Log-Report. Meta-POD processed with
# OODoc into POD and HTML manual-pages.  See README.md
# Copyright Mark Overmeer.  Licensed under the same terms as Perl itself.

package Dancer2::Logger::LogReport;
# ABSTRACT: Dancer2 logger engine for Log::Report

use strict;
use warnings;

use Moo;
use Dancer2::Core::Types;
use Scalar::Util qw/blessed/;
use Log::Report  'log-report', syntax => 'REPORT';

our $AUTHORITY = 'cpan:MARKOV';

my %level_dancer2lr =
  ( core  => 'TRACE'
  , debug => 'TRACE'
  );

with 'Dancer2::Core::Role::Logger';

# Set by calling function
has dispatchers =>
  ( is     => 'ro'
  , isa    => Maybe[HashRef]
  );

sub BUILD
{   my $self     = shift;
    my $configs  = $self->dispatchers || {default => undef};
    $self->{use} = [keys %$configs];

    dispatcher 'do-not-reopen';

    foreach my $name (keys %$configs)
    {   my $config = $configs->{$name} || {};
        if(keys %$config)
        {   my $type = delete $config->{type}
                or die "dispatcher configuration $name without type";

            dispatcher $type, $name, %$config;
        }
    }
}

around 'error' => sub {
    my ($orig, $self) = (shift, shift);

    # If it's a route exception (generated by Dancer) and we're also using the
    # Plugin, then the plugin will handle the exception using its own hook into
    # the error system. This should be able to removed in the future with
    # https://github.com/PerlDancer/Dancer2/pull/1287
    return if $_[0] =~ /^Route exception/
           && $INC{'Dancer2/Plugin/LogReport.pm'};

    $self->log(error => @_);
};

=chapter NAME

Dancer2::Logger::LogReport - reroute Dancer2 logs into Log::Report

=chapter SYNOPSIS

  # This module is loaded when configured.  It does not provide
  # end-user functions or methods.

  # See L<Dancer2::Plugin::LogReport/"DETAILS">
  
=chapter DESCRIPTION

[The Dancer2 plugin was contributed by Andrew Beverley]

This logger allows the use of the many logging backends available
in M<Log::Report>.  It will process all of the Dancer2 log messages,
and also allow any other module to use the same logging facilities. The
same log messages can be sent to multiple destinations at the same time
via flexible dispatchers.

If using this logger, you may also want to use
M<Dancer2::Plugin::LogReport>

Many log back-ends, like syslog, have more levels of system messages.
Modules who explicitly load this module can use the missing C<assert>,
C<notice>, C<panic>, and C<alert> log levels.  The C<trace> name is
provided as well: when you are debugging, you add a 'trace' to your
program... it's just a better name than 'debug'. You will need to load
Log::Report in order to use the additional levels; if doing so directly within
a Dancer2 application (not a sub-module), then you will either need to load
Log::Report with C<syntax, 'LONG'> or use M<Dancer2::Plugin::LogReport> to
prevent namespace clashes.

=head2 Log Format

If using this module on its own (such as a drop-in replacement for
M<Dancer2::Logger::Syslog>), then the logging format is configured as with any
other Dancer logger. If using this module with M<Dancer2::Plugin::LogReport>,
then log_format is ignored and messages are not formatted, in order to keep the
message format consistent regardless of where the message was generated (be it
another module using Log::Report, the plugin, or Dancer itself). In this case,
the log format should be configured using the applicable dispatcher (such as
M<Log::Report::Dispatcher::Syslog::new(format)>).
    
If also using with the L<Log::Report> logging functions, then you probably want
to set a very simple C<logger_format>, because the dispatchers do already add
some of the fields that the default C<simple> format adds.  For instance, to
get the filename/line-number in messages depends on the dispatcher 'mode' (f.i.
'DEBUG').

You also want to set the Dancer2 log level to C<debug>, because level filtering
is controlled per dispatcher (as well).

See L<Dancer2::Plugin::LogReport/"DETAILS"> for examples.

=chapter METHODS

=method log $level, $params

=cut

sub log   # no protoypes in Dancer2
{   my ($self, $level, $msg) = @_;

    my %options;
    # If only using the logger on its own (without the associated plugin), make
    # it behave like a normal Dancer logger
    unless ($INC{'Dancer2/Plugin/LogReport.pm'})
    {   $msg = $self->format_message($level, $msg);
        $options{is_fatal} = 0;
    }

    # the levels are nearly the same.
    my $reason = $level_dancer2lr{$level} || uc $level;

    report \%options, $reason => $msg;
    undef;
}
 
1;

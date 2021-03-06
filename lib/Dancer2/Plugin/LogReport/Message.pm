# This code is part of distribution Log-Report. Meta-POD processed with
# OODoc into POD and HTML manual-pages.  See README.md
# Copyright Mark Overmeer.  Licensed under the same terms as Perl itself.

package Dancer2::Plugin::LogReport::Message;
use parent 'Log::Report::Message';

use strict;
use warnings;

=chapter NAME

Dancer2::Plugin::LogReport::Message - extended Log::Report message class

=chapter SYNOPSIS

  In your template:

  [% FOR message IN messages %]
    <div class="alert alert-[% message.bootstrap_color %]">
      [% message.toString | html_entity %]
    </div>
  [% END %]

=chapter DESCRIPTION

[The Dancer2 plugin was contributed by Andrew Beverley]

This class is an extension of L<Log::Report::Message>, with functions
specifically designed for Dancer applications. Minimal functions are
provided (currently only aimed at Bootstrap), but ideas for new ones are
welcome.

=chapter METHODS
=cut

sub init($)
{   my ($self, $args) = @_;
    $self->SUPER::init($args);
    $self;
}

=method reason

Get or set the reason of a message
=cut

sub reason
{   my $self = shift;
    $self->{reason} = $_[0] if exists $_[0];
    $self->{reason};
}

my %reason2color =
    ( TRACE   => 'info'
    , ASSERT  => 'info'
    , INFO    => 'info'
    , NOTICE  => 'info'
    , WARNING => 'warning'
    , MISTAKE => 'warning'
    );

=method bootstrap_color

Get a suitable bootstrap context color for the message. This can be
used as per the SYNOPSIS.

C<success> is used for M<Dancer2::Plugin::LogReport::success()> messages,
C<info> colors are used for messages C<notice> and below, C<warning> is used
for C<warning> and C<mistake>, C<danger> is used for all other messages
=cut

sub bootstrap_color
{  my $self = shift;
   return 'success' if $self->inClass('success');
   $reason2color{$self->reason} || 'danger';
}

1;

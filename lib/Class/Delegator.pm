package Class::Delegator;

# $Id: Delegator.pm 1168 2005-01-28 00:04:16Z theory $

use strict;

$Class::Delegator::VERSION = '0.01';

=begin comment

Fake-out Module::Build. Delete if it ever changes to support =head1 headers
other than all uppercase.

=head1 NAME

Class::Delegator - Simple and fast object-oriented delegation

=end comment

=head1 Name

Class::Delegator - Simple and fast object-oriented delegation

=head1 Synopsis

  package Car;

  use Class::Delegator
      send => 'start',
      to   => '{engine}',

      send => 'power',
      to   => 'flywheel',
      as   => 'brake',

      send => [qw(play pause rewind fast_forward shuffle)],
      to   => 'ipod',

      send => [qw(accelerate decelerate)],
      to   => 'brakes',
      as   => [qw(start stop)],
  ;


=head1 Description

This module provides a subset of the functionality of Damian Conway's lovely
L<Class::Delegation|Class::Delegation> module. Why a subset? Well, I didn't
need all of the fancy matching semantics or dispatching to multiple delegated
attributes, just string string specifications to map delegations. Furthermore,
I wanted it to be fast. And finally, since Class::Delegation uses an C<INIT>
block to do its magic, it doesn't work in persistent environments that don't
execute C<INIT> blocks, such as in L<mod_perl|mod_perl>. The specification
rules differ slightly from those of Class::Delegation, so this module isn't a
drop-in replacement for Class::Delegation. Read on for details.

=head2 Specifying methods to be delegated

The names of methods to be redispatched can be specified using the C<send>
parameter. This parameter may be specified as a single string or as an array
of strings. A single string specifies a single method to be delegated, while
an array reference is a list of methods to be delegated.

=head2 Specifying attributes to be delegated to

Use the C<to> parameter to specify the attribute or method to which the
methods specified by the C<send> parameter are to be delegated. The semantics
of the C<to> parameter are a bit different from Class::Delegation. In order to
ensure the fastest performance possible, this module simply installs methods
into the calling class to handle the delegation. There is no use of
C<$AUTOLOAD> or other such trickery. But since the new methods are installed
by C<eval>ing a string, the C<to> parameter for each delegation statement must
be specified in the manner appropriate to accessing the underlying attribute.
For example, to delegate a method call to an attribute stored in a hash key,
simply wrap the key in braces:

  use Class::Delegator
      send => 'start',
      to   => '{engine}',
  ;

To delegate to a method, simply name the method:

  use Class::Delegator
      send => 'power',
      to   => 'flywheel',
  ;

If your objects are array-based, wrap the appropriate array index number in
brackets:

  use Class::Delegator
      send => 'idle',
      to   => '[3]',
  ;

And so on.

=head2 Specifying the name of a delegated method

Sometimes it's necessary for the name of the method that's being delegated to
be different from the name of the method to which you're delegating execution.
For example, your class might already have a method with the same name as the
method to which you're delegating. The C<as> parameter allows you translate
the method name or names in a delegation statement. The value associated with
an C<as> parameter specifies the name of the method to be invoked, and may be
a string or an array (with the number of elements in the array matching the
number of elements in a corresponding C<send> array).

If the attribute is specified via a single string, that string is taken as the
name of the attribute to which the associated method (or methods) should be
delegated. For example, to delegate invocations of C<$self-E<gt>power(...)> to
C<$self-E<gt>{flywheel}-E<gt>power(...)>:

  use Class::Delegator
      send => 'power',
      to   => '{flywheel}',
      as   => 'brake',
  ;

If both the C<send> and the C<as> parameters specify array references, each
local method name and deleted method name form a pair, which is invoked. For
example:

  use Class::Delegator
      send => [qw(accelerate decelerate)],
      to   => 'brakes',
      as   => [qw(start stop)],
  ;

In this example, the C<accelerate> method will be delegated to the C<start>
method of the <brakes> attribute and the C<decelerate> method will be
delegated to the C<stop> method of the C<brakes> attribute.

=cut

##############################################################################

sub import {
    my $class = shift;
    my $caller = caller;
    while (@_) {
        my ($key, $send) = (shift, shift);
        _die(qq{Expected "send => <method spec>" but found "$key => $send"})
          unless $key eq 'send';

        ($key, my $to) = (shift, shift);
        _die(qq{Expected "to => <attribute spec>" but found "$key => $to"})
          unless $key eq 'to';

        my $as;
        if ($_[0] || '' eq 'as') {
            $as = (shift, shift);
            ($send, $as) = ([$send], [$as]) unless ref $send;
            _die('Arrays specified for "send" and "as" must be same length')
              unless @$as == @$send;
        } else {
            $send = [$send] unless ref $send;
            $as = [@$send];
        }

        while (@$send) {
            my $s = shift @$send;
            my $m = shift @$as;
            no strict 'refs';
            *{"${caller}::$s"} = eval "sub { shift->$to->$m(\@_) };";
        }
    }
}

sub _die {
    require Carp;
    Carp::croak(@_);
}

##############################################################################

=head1 Bugs

Please send bug reports to <bug-class-delegator@rt.cpan.org>.

=head1 Author

=begin comment

Fake-out Module::Build. Delete if it ever changes to support =head1 headers
other than all uppercase.

=head1 AUTHOR

=end comment

David Wheeler <david@kineticode.com>

=head1 Copyright and License

Copyright (c) 2005 Kineticode, Inc. All Rights Reserved.

This module is free software; you can redistribute it and/or modify it under the
same terms as Perl itself.

=cut

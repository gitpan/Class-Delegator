#!perl -w

# $Id: base.t 1168 2005-01-28 00:04:16Z theory $

use strict;
use Test::More tests => 56;

BEGIN { use_ok('Class::Delegator') }

{
    package MyTest::Foo;
    sub new { bless {} }
    sub bar {
        my $self = shift;
        return $self->{bar} unless @_;
        $self->{bar} = shift;
    };
    sub try {
        my $self = shift;
        return $self->{try} unless @_;
        $self->{try} = shift;
    };
}

can_ok 'MyTest::Foo', 'new';
can_ok 'MyTest::Foo', 'bar';

{
    package MyTest::Simple;
    sub new { bless { foo => MyTest::Foo->new } }
    use Class::Delegator
      send => 'bar',
      to   => '{foo}',
    ;
}

can_ok 'MyTest::Simple', 'bar';
ok my $d = MyTest::Simple->new, "Construct new simple object";
is $d->bar, $d->{foo}->bar, "Make sure the simple values are the same";
ok $d->bar('hello'), "Set the value via the simple delegate";
is $d->bar, 'hello', "Make sure that the simple attribute was set";
is $d->{foo}->bar, 'hello', "And that it is in the simple contained object";

{
    package MyTest::As;
    sub new { bless { foo => MyTest::Foo->new } }
    use Class::Delegator
      send => 'yow',
      to   => '{foo}',
      as   => 'bar',
    ;
}

ok ! MyTest::As->can('bar'), "MyTest::As cannot 'bar'";
can_ok 'MyTest::As', 'yow';
ok $d = MyTest::As->new, "Construct new as object";
is $d->yow, $d->{foo}->bar, "Make sure the as values are the same";
ok $d->yow('hello'), "Set the as value via the delegate";
is $d->yow, 'hello', "Make sure that the as attribute was set";
is $d->{foo}->bar, 'hello', "And that it is in the as contained object";

{
    package MyTest::Method;
    sub new { bless { foo => MyTest::Foo->new } }
    sub foo { shift->{foo} }
    use Class::Delegator
      send => 'bar',
      to   => 'foo',
    ;
}

can_ok 'MyTest::Method', 'bar';
ok $d = MyTest::Method->new, "Construct new meth object";
is $d->bar, $d->foo->bar, "Make sure the meth values are the same";
ok $d->bar('hello'), "Set the value via the meth delegate";
is $d->bar, 'hello', "Make sure that the meth attribute was set";
is $d->foo->bar, 'hello', "And that it is in the contained object";

{
    package MyTest::Array;
    sub new { bless [ MyTest::Foo->new ] }
    use Class::Delegator
      send => 'bar',
      to   => '[0]',
    ;
}

can_ok 'MyTest::Array', 'bar';
ok $d = MyTest::Array->new, "Construct new array object";
is $d->bar, $d->[0]->bar, "Make sure the array values are the same";
ok $d->bar('hello'), "Set the value via the array delegate";
is $d->bar, 'hello', "Make sure that the array attribute was set";
is $d->[0]->bar, 'hello', "And that it is in the contained object";

{
    package MyTest::Multi;
    sub new { bless { foo => MyTest::Foo->new } }
    use Class::Delegator
      send => [qw(bar try)],
      to   => '{foo}',
    ;
}

can_ok 'MyTest::Multi', 'bar';
can_ok 'MyTest::Multi', 'try';
ok $d = MyTest::Multi->new, "Construct new multi object";
is $d->bar, $d->{foo}->bar, "Make sure the bar values are the same";
ok $d->bar('hello'), "Set the value via the bar delegate";
is $d->bar, 'hello', "Make sure that the bar attribute was set";
is $d->{foo}->bar, 'hello', "And that it is in the foo contained object";
is $d->try, $d->{foo}->try, "Make sure the try values are the same";
ok $d->try('hello'), "Set the value via the try delegate";
is $d->try, 'hello', "Make sure that the try attribute was set";
is $d->{foo}->try, 'hello', "And that it is in the foo contained object";

{
    package MyTest::MutiAs;
    sub new { bless { foo => MyTest::Foo->new } }
    use Class::Delegator
      send => [qw(rab yrt)],
      to   => '{foo}',
      as   => [qw(bar try)],
    ;
}

can_ok 'MyTest::MutiAs', 'rab';
can_ok 'MyTest::MutiAs', 'yrt';
ok $d = MyTest::MutiAs->new, "Construct new multi object";
is $d->rab, $d->{foo}->bar, "Make sure the rab values are the same";
ok $d->rab('hello'), "Set the value via the rab delegate";
is $d->rab, 'hello', "Make sure that the rab attribute was set";
is $d->{foo}->bar, 'hello', "And that it is in the foo contained object";
is $d->yrt, $d->{foo}->try, "Make sure the yrt values are the same";
ok $d->yrt('hello'), "Set the value via the yrt delegate";
is $d->yrt, 'hello', "Make sure that the yrt attribute was set";
is $d->{foo}->try, 'hello', "And that it is in the foo contained object";

{
    package MyTest::Errors;
    use Test::More;
    eval { Class::Delegator->import(foo => 'bar') };
    ok my $err = $@, "Catch 'missing send' exception";
    like $err, qr/Expected "send => <method spec>" but found "foo => bar"/,
      "Caught correct 'missing send' exception";

    eval { Class::Delegator->import(send => 'foo', foo => 'bar') };
    ok $err = $@, "Catch 'missing to' exception";
    like $err, qr/Expected "to => <attribute spec>" but found "foo => bar"/,
      "Caught correct 'missing to' exception";

    eval { Class::Delegator->import(send => ['foo'], to => 'bar', as => []) };
    ok $err = $@, "Catch 'array length' exception";
    like $err, qr/Arrays specified for "send" and "as" must be same length/,
      "Caught correct 'array length' exception";
}


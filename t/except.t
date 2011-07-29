use strict;
use warnings;
use Test::More tests => 3;

sub bar {}
sub moo {}
sub baz {}

BEGIN {
   *Foo::bar = \&bar;
   *Foo::moo = \&moo;
   *Foo::baz = \&baz;
}

{
    package Foo;
    use namespace::autoclean -except => ['moo', 'bar'];
}

ok( Foo->can('bar'), '-except works 1');
ok( Foo->can('moo'), '-except works 2');
ok(!Foo->can('baz'), 'imported method not specified in -except removed');

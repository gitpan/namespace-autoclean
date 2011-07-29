use strict;
use warnings;
use Test::More tests => 5;

{
    package Foo;
    require namespace::autoclean;
    &::ok( eval { namespace::autoclean->import; 1 });
    &::ok( eval { namespace::autoclean->import(-cleanee => 'Foo'); 1 });
    &::ok( eval { namespace::autoclean->import(-also    => 'foo'); 1 });
    &::ok( eval { namespace::autoclean->import(-except  => 'foo'); 1 });
    &::ok(!eval { namespace::autoclean->import(-haha    => 'foo'); 1 });
}

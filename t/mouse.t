use strict;
use warnings;
use Test::More tests => 8;

{
    package Foo;
    use Mouse;
    use Sub::Name;
    use overload '""' => \&affe;
    sub bar { }
    use namespace::autoclean;
    sub moo { }
    BEGIN { *kooh = *kooh = do { package Moo; sub { }; }; }
    BEGIN { *affe = *affe = sub { 'affe' }; }
    BEGIN { *tiger = *tiger = subname tiger => sub { }; }
}

ok(!Class::MOP->VERSION);
ok( Foo->can('bar'));
ok( Foo->can('moo'));
ok(!Foo->can('kooh'));
ok( Foo->can('affe'));
ok( Foo->new.'' eq 'affe');
ok( Foo->can('tiger'));
ok(!Foo->can('subname'));

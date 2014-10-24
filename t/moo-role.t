use strict;
use warnings;
use Test::More 0.88;
use Test::Requires qw(Moo);

{
  package Some::Role;
  use Moo::Role;
  use namespace::autoclean;
  sub role_method { 42 }
}

{
  package Consuming::Class;
  use Moo;
  use namespace::autoclean;
  with 'Some::Role';
}

{
  package Consuming::Class::InBegin;
  use Moo;
  use namespace::autoclean;
  BEGIN { with 'Some::Role' };
}


{
  local $TODO = "Moo::Role's meta not seen as method";
  can_ok('Some::Role', 'meta');
}
can_ok('Consuming::Class', 'role_method');
can_ok('Consuming::Class::InBegin', 'role_method');
is $INC{'Class/MOP/Class.pm'}, undef, 'Moose not loaded';

done_testing;

use strict;
use warnings;

package namespace::autoclean;
BEGIN {
  $namespace::autoclean::AUTHORITY = 'cpan:FLORA';
}
BEGIN {
  $namespace::autoclean::VERSION = '0.1202';
}
# ABSTRACT: Keep imports out of your namespace

use B::Hooks::EndOfScope;
use List::Util qw( first );
use namespace::clean 0.20;


my $MCC;        # metaclass class
my $GETMETHODS; # function to get real methods of class
my $GETSYMS;    # function to get code symbols in package

sub import {
    my ($class, %args) = @_;

    my @bad = grep { !/^-(except|also|cleanee)\z/ } keys %args;
    die "Invalid autoclean key(s): @bad" if @bad;

    my $subcast = sub {
        my $i = shift;
        return $i if ref $i eq 'CODE';
        return sub { $_ =~ $i } if ref $i eq 'Regexp';
        return sub { $_ eq $i };
    };

    my $runtest = sub {
        my ($code, $method_name) = @_;
        local $_ = $method_name;
        return $code->();
    };

    my $cleanee = exists $args{-cleanee} ? $args{-cleanee} : scalar caller;

    my @also = map { $subcast->($_) } (
        exists $args{-also}
        ? (ref $args{-also} eq 'ARRAY' ? @{ $args{-also} } : $args{-also})
        : ()
    );
    my @except = map { $subcast->($_) } (
        exists $args{-except}
        ? (ref $args{-except} eq 'ARRAY' ? @{ $args{-except} } : $args{-except})
        : ()
    );

    unless ($MCC) {
        if (exists $INC{'Mouse.pm'}) {
            require Package::Stash;
            require Sub::Identify;
            $MCC = 'Mouse::Meta::Class';
            $GETSYMS    = sub { Package::Stash->new($_[0]->name)->list_all_symbols('CODE') };
            $GETMETHODS = sub {
                my $pkg = $_[0]->name;
                grep { ; no strict 'refs';
                       my $s = Sub::Identify::stash_name(\&{"${pkg}::$_"});
                       $s && ($s eq $pkg || $s eq 'constant' || $s eq '__ANON__') }
                  $_[0]->get_method_list
            };
        }
        else {
            require Class::MOP;
            Class::MOP->VERSION(0.80);
            $MCC = 'Class::MOP::Class';
            $GETSYMS    = sub { $_[0]->list_all_package_symbols('CODE') };
            $GETMETHODS = 'get_method_list';
        }
    };

    on_scope_end {
        my $meta = $MCC->initialize($cleanee);

        my %methods = map { ($_ => 1) } $meta->$GETMETHODS;
        $methods{meta} = 1 if $meta->isa('Moose::Meta::Role') && Moose->VERSION < 0.90;

        for my $method (keys %methods) {
           delete $methods{$method} if first { $runtest->($_, $method) } @also;
        }

        my @symbols = $meta->$GETSYMS;
        for my $symbol (@symbols) {
            next if exists $methods{$symbol};
            $methods{ $symbol } = 1 if first { $runtest->($_, $symbol) } @except;
        }

        namespace::clean->clean_subroutines($cleanee, grep { !$methods{$_} } @symbols);
    };
}

1;

__END__
=pod

=encoding utf-8

=head1 NAME

namespace::autoclean - Keep imports out of your namespace

=head1 SYNOPSIS

    package Foo;
    use namespace::autoclean;
    use Some::Package qw/imported_function/;

    sub bar { imported_function('stuff') }

    # later on:
    Foo->bar;               # works
    Foo->imported_function; # will fail. imported_function got cleaned after compilation

=head1 DESCRIPTION

When you import a function into a Perl package, it will naturally also be
available as a method.

The C<namespace::autoclean> pragma will remove all imported symbols at the end
of the current package's compile cycle. Functions called in the package itself
will still be bound by their name, but they won't show up as methods on your
class or instances.

This module is very similar to L<namespace::clean|namespace::clean>, except it
will clean all imported functions, no matter if you imported them before or
after you C<use>d the pragma. It will also not touch anything that looks like a
method, according to either C<Class::MOP::Class::get_method_list> or, if Mouse
is already loaded, C<Mouse::Meta::Class::get_method_list>.

If you're writing an exporter and you want to clean up after yourself (and your
peers), you can use the C<-cleanee> switch to specify what package to clean:

  package My::MooseX::namespace::autoclean;
  use strict;

  use namespace::autoclean (); # no cleanup, just load

  sub import {
      namespace::autoclean->import(
        -cleanee => scalar(caller),
      );
  }

=head1 PARAMETERS

=head2 -also => [ ITEM | REGEX | SUB, .. ]

=head2 -also => ITEM

=head2 -also => REGEX

=head2 -also => SUB

=head2 -except => [ ITEM | REGEX | SUB, .. ]

=head2 -except => ITEM

=head2 -except => REGEX

=head2 -except => SUB

Sometimes you don't want to clean imports only, but also helper functions
you're using in your methods. The C<-also> switch can be used to declare a list
of functions that should be removed additional to any imports:

    use namespace::autoclean -also => ['some_function', 'another_function'];

Similarly, sometimes you don't want to clean all the exporters.  The C<-except>
switch can be used to declare a list of imports that should not be removed:

    use namespace::autoclean -except => ['import'];

If only one function needs to be additionally cleaned the C<-also> and C<-except>
switches also accept a plain string:

    use namespace::autoclean -also => 'some_function';

In some situations, you may wish for a more I<powerful> cleaning solution.

The C<-also> and C<-except> switches can take a Regex or a CodeRef to match
against local function names to clean.

    use namespace::autoclean -also => qr/^_/

    use namespace::autoclean -also => sub { $_ =~ m{^_} };

    use namespace::autoclean -also => [qr/^_/ , qr/^hidden_/ ];

    use namespace::autoclean -also => [sub { $_ =~ m/^_/ or $_ =~ m/^hidden/ }, sub { uc($_) == $_ } ];

=head1 SEE ALSO

L<namespace::clean>

L<Class::MOP>

L<Mouse>

L<Sub::Identify>

L<Package::Stash>

L<B::Hooks::EndOfScope>

=head1 AUTHOR

Chip Salzenberg <chip@pobox.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Florian Ragwitz, Tomas Duran, Chip Salzenberg.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


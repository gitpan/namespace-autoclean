
use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
  DISTNAME  => 'namespace-autoclean',
  NAME      => 'namespace::autoclean',
  AUTHOR    => 'Florian\ Ragwitz\ \<rafl\@debian\.org\>',
  ABSTRACT  => 'Keep\ imports\ out\ of\ your\ namespace',
  VERSION   => '0.08',
  EXE_FILES => [ qw() ],
  (eval { ExtUtils::MakeMaker->VERSION(6.21) } ? (LICENSE => 'perl') : ()),
  PREREQ_PM    => {
    "List::Util" => '0',
    "namespace::clean" => '0.11',
    "Class::MOP" => '0.80',
    "B::Hooks::EndOfScope" => '0.07',
  },
);

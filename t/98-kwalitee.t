#!perl -w
use strict;
use Test::More;

plan skip_all => "Test::Kwalitee required for checking distribution"
    unless eval { require Test::Kwalitee };

Test::Kwalitee->import(tests => [qw< -has_meta_yml >]);

unlink "Debian_CPANTS.txt";

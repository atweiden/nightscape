use v6;
use Nightscape::Types;
unit class Nightscape::Entry::Posting::Account;

has Silo $.silo;
has VarName $.entity;
has VarName @.subaccount;

# vim: ft=perl6
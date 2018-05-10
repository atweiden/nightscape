use v6;
use Nightscape::Types;
use TXN::Parser::ParseTree;
use TXN::Parser::Types;

# p6doc {{{

=begin pod
=head NAME

Nightscape::DX

=head DESCRIPTION

C<Nightscape::DX> contains classes derived from
C<TXN::Parser::ParseTree>. These classes are useful in the construction
of accounting reports.
=end pod

# end p6doc }}}

# class Account {{{

class Account
{
    has Array[Rat:D] %.balance{AssetCode:D};
    has Account:D %.subaccount{VarName:D};

    method clone(::?CLASS:D: --> Account:D)
    {
        my Array[Rat:D] %balance{AssetCode:D} =
            %.balance.kv.hyper.map(->
                AssetCode:D $asset-code, Rat:D @delta {
                    $asset-code => @delta.clone
            });
        my Account:D %subaccount{VarName:D} =
            %.subaccount.kv.hyper.map(->
                VarName:D $subaccount-name, Account:D $account {
                    $subaccount-name => $account.clone
            });
        my Account $account .= new(:%balance, :%subaccount);
    }

    method mkbalance(::?CLASS:D: AssetCode:D $asset-code, Rat:D $delta --> Nil)
    {
        push(%!balance{$asset-code}, $delta);
    }

    method mksubaccount(::?CLASS:D: VarName:D $subaccount-name --> Nil)
    {
        %!subaccount{$subaccount-name} = Account.new;
    }
}

# end class Account }}}
# class Coa {{{

class Coa
{
    # defaults to one account per C<Silo>
    has Account:D %.account{Silo:D} =
        Silo::.keys.hyper.map({ ::($_) }) Z=> Account.new xx Silo::.keys.elems;

    method clone(::?CLASS:D: --> Coa:D)
    {
        my Account:D %account{Silo:D} =
            %.account.kv.hyper.map(-> Silo:D $silo, Account:D $account {
                $silo => $account.clone
            });
        my Coa $coa .= new(:%account);
    }

    method in-account(
        Account:D $account,
        *@subaccount-name
        --> Account:D
    ) is rw
    {
        in-account($account, @subaccount-name);
    }

    multi sub in-account(
        Account:D $account,
        *@ (
            VarName:D $subaccount-name where { $account.subaccount{$_}:exists },
            *@tail
        )
        --> Account:D
    ) is rw
    {
        my Account:D $subaccount := $account.subaccount{$subaccount-name};
        my VarName:D @subaccount = @tail;
        in-account($subaccount, @subaccount);
    }

    multi sub in-account(
        Account:D $account,
        *@s (
            VarName:D $subaccount-name,
            *@
        )
        --> Account:D
    ) is rw
    {
        $account.mksubaccount($subaccount-name);
        my VarName:D @subaccount = @s;
        in-account($account, @subaccount);
    }

    multi sub in-account(
        Account:D $account,
        *@
        --> Account:D
    ) is rw
    {
        $account;
    }
}

# end class Coa }}}
# class Hodl {{{

class Hodl {*}

# end class Hodl }}}
# class Entryʹ {{{

class Entryʹ
{
    # C<Entry> from which C<Entry′> is derived
    has Entry:D $.entry is required;
    has Entry::Postingʹ:D @.postingʹ is required;
    has Coa:D $.coa is required;
    has Hodl:D $.hodl is required;
}

# end class Entryʹ }}}
# class Entry::Postingʹ {{{

class Entry::Postingʹ
{
    # C<Entry::Posting> from which C<Entry::Posting′> is derived
    has Entry::Posting:D $.posting is required;
    has Coa:D $.coa is required;
    has Hodl:D $.hodl is required;
}

# end class Entry::Postingʹ }}}

# vim: set filetype=perl6 foldmethod=marker foldlevel=0:

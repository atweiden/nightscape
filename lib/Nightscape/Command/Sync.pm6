use v6;
use Nightscape::Config;
use Nightscape::Dx;
use Nightscape::Types;
use TXN::Parser::ParseTree;
use TXN::Parser::Types;
unit class Nightscape::Command::Sync;

# method sync {{{

method sync(
    *%opts (
        Int :date-local-offset($),
        Str :include-lib($)
    ),
    *@ledger
    --> List:D
)
{
    my List:D $sync = self!sync(|%opts, |@ledger);
}

# end method sync }}}
# method !sync {{{

method !sync(
    *%opts (
        Int :date-local-offset($),
        Str :include-lib($)
    ),
    *@ledger
    --> List:D
)
{
    my AbsolutePath:D $pkg-dir = $*config.pkg-dir;
    my List:D $sync = sync($*config.ledger, :$pkg-dir, |%opts, |@ledger);
}

# end method !sync }}}
# sub sync {{{

multi sub sync(
    Nightscape::Config::Ledger:D @l,
    *%opts (
        AbsolutePath:D :pkg-dir($)!,
        Int :date-local-offset($),
        Str :include-lib($)
    ),
    *@request where .so
    --> List:D
)
{
    my Nightscape::Config::Ledger:D @ledger =
        grep-ledger-for-request(@l, @request);
    my List:D $sync = sync(:@ledger, |%opts).List;
}

multi sub sync(
    Nightscape::Config::Ledger:D @ledger,
    *%opts (
        AbsolutePath:D :pkg-dir($)!,
        Int :date-local-offset($),
        Str :include-lib($)
    ),
    *@
    --> List:D
)
{
    my List:D $sync = sync(:@ledger, |%opts).List;
}

multi sub sync(
    Nightscape::Config::Ledger:D :@ledger!,
    *%opts (
        AbsolutePath:D :pkg-dir($)! where .so,
        Int :date-local-offset($),
        Str :include-lib($)
    )
    --> List:D
)
{
    my List:D $sync =
        @ledger.hyper.map(-> Nightscape::Config::Ledger:D $ledger {
            sync(:$ledger, |%opts)
        }).List;
}

multi sub sync(
    Nightscape::Config::Ledger::FromFile:D :ledger($cfg-ledger)!,
    AbsolutePath:D :pkg-dir($)! where .so,
    *%opts (
        Int :date-local-offset($),
        Str :include-lib($)
    )
    --> Ledgerʹ:D
)
{
    my %pkg = $cfg-ledger.made(|%opts);
    my Ledger:D $ledger = %pkg<ledger>;
    my Coa $coa .= new;
    my Hodl $hodl .= new;
    my Ledgerʹ:D $ledgerʹ =
        $*registry.send-to-hooks(LEDGER, [$ledger, $coa, $hodl]);
}

multi sub sync(
    Nightscape::Config::Ledger::FromPkg:D :ledger($cfg-ledger)!,
    AbsolutePath:D :$pkg-dir! where .so,
    *% (
        Int :date-local-offset($),
        Str :include-lib($)
    )
    --> Ledgerʹ:D
)
{
    my %pkg = $cfg-ledger.made(:$pkg-dir);
    my Ledger:D $ledger = %pkg<ledger>;
    my Coa $coa .= new;
    my Hodl $hodl .= new;
    my Ledgerʹ:D $ledgerʹ =
        $*registry.send-to-hooks(LEDGER, [$ledger, $coa, $hodl]);
}

# end sub sync }}}


# -----------------------------------------------------------------------------
# helper functions
# -----------------------------------------------------------------------------

# sub grep-ledger-for-request {{{

sub grep-ledger-for-request(
    Nightscape::Config::Ledger:D @ledger,
    Str:D @request
    --> Array[Nightscape::Config::Ledger:D]
)
{
    my Nightscape::Config::Ledger:D @grep-ledger-for-request =
        @ledger.hyper.grep(-> Nightscape::Config::Ledger:D $ledger {
            is-ledger-for-request($ledger, @request)
        });
}

multi sub is-ledger-for-request(
    Nightscape::Config::Ledger::FromFile:D $ledger,
    Str:D @request
    --> Bool:D
)
{
    my Bool:D $is-ledger-for-request = @request.grep($ledger.code).so;
}

multi sub is-ledger-for-request(
    Nightscape::Config::Ledger::FromPkg:D $ledger,
    Str:D @request
    --> Bool:D
)
{
    my Bool:D $is-ledger-for-request = @request.grep($ledger.pkgname).so;
}

# end sub grep-ledger-for-request }}}

# vim: set filetype=perl6 foldmethod=marker foldlevel=0:

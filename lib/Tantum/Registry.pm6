use v6;
use Tantum::Dx::Coa;
use Tantum::Dx::Entry::Posting;
use Tantum::Dx::Entry;
use Tantum::Dx::Hodl;
use Tantum::Dx::Ledger;
use Tantum::Hook::Coa;
use Tantum::Hook::Entry::Posting;
use Tantum::Hook::Entry;
use Tantum::Hook::Hodl;
use Tantum::Hook::Hook;
use Tantum::Hook::Ledger;
use Tantum::Hook::Response;
use Tantum::Hook;
use Tantum::Types;
use TXN::Parser::ParseTree;
use X::Tantum::Registry;
unit class Registry;

has Hook:D @!hook =
    Hook::Entry::Posting.new,
    Hook::Entry.new,
    Hook::Ledger.new,
    Hook::Coa.new,
    Hook::Hodl.new,
    Hook::Hook.new;

# method hook {{{

method hook(::?CLASS:D: --> Array[Hook:D])
{
    my Hook:D @hook = @!hook;
}

# end method hook }}}
# method register {{{

method register(Hook:D $hook --> Nil)
{
    push(@!hook, $hook);
}

# end method register }}}
# method unregister {{{

# tbd
method unregister(Hook:D $hook --> Nil)
{*}

# end method unregister }}}
# method query-hooks {{{

# query hooks by type
method query-hooks(::?CLASS:D: HookType $type --> Array[Hook[$type]])
{
    my Hook[$type] @hook = @.hook.grep(Hook[$type]);
}

# end method query-hooks }}}
# method send-to-hooks {{{

method send-to-hooks(
    ::?CLASS:D:
    HookType:D $type,
    @arg
    --> Hook::Response[$type]
)
{
    # sort C<Hook>s of this C<HookType> by priority descending
    my Hook[$type] @hook =
        self.query-hooks($type).sort({ $^b.priority > $^a.priority });
    my Hook::Response[$type] $response = send-to-hooks(@hook, @arg);
}

# --- POSTING {{{

multi sub send-to-hooks(
    Hook[POSTING] @hook,
    @arg (Entry::Posting:D $, Entry::Header:D $),
    *%opts (
        Hook:U :applied(@),
        Entry::Postingʹ:D :carry(@)
    )
    --> Hook::Response[POSTING]
)
{
    my Hook[POSTING] $hook = @hook.first({ .is-match(|@arg, |%opts) });
    my Hook::Response[POSTING] $response =
        send-to-hooks($hook, @hook, @arg, |%opts);
}

multi sub send-to-hooks(
    Hook[POSTING] $hook where .defined,
    Hook[POSTING] @hook,
    @arg (Entry::Posting:D $, Entry::Header:D $),
    *%opts (
        Hook:U :applied(@a),
        Entry::Postingʹ:D :carry(@c)
    )
    --> Hook::Response[POSTING]
)
{
    my Entry::Postingʹ:D $postingʹ = $hook.apply(|@arg, |%opts);
    my Hook:U @applied = |@a, $hook.WHAT;
    my Entry::Postingʹ:D @carry = |@c, $postingʹ;
    my Hook::Response[POSTING] $response =
        send-to-hooks(@hook, @arg, :@applied, :@carry);
}

multi sub send-to-hooks(
    Hook[POSTING] $,
    Hook[POSTING] @,
    @ (Entry::Posting:D $, Entry::Header:D $),
    *% (
        Hook:U :@applied! where .so,
        Entry::Postingʹ:D :@carry! where .so
    )
    --> Hook::Response[POSTING]
)
{
    my Hash[Entry::Postingʹ:D,Hook:U] @made = @applied Z=> @carry;
    my Hook::Response[POSTING] $response .= new(:@made);
}

multi sub send-to-hooks(
    Hook[POSTING] $,
    Hook[POSTING] @,
    @ (Entry::Posting:D $, Entry::Header:D $),
    *% (
        Hook:U :applied(@),
        Entry::Postingʹ:D :carry(@)
    )
    --> Nil
)
{
    die(X::Tantum::Registry::NoHookApplied.new(POSTING));
}

# --- end POSTING }}}
# --- ENTRY {{{

multi sub send-to-hooks(
    Hook[ENTRY] @hook,
    @arg (Entry:D $, Coa:D $, Hodl:D $),
    *%opts (
        Hook:U :applied(@),
        Entryʹ:D :carry(@)
    )
    --> Hook::Response[ENTRY]
)
{
    my Hook[ENTRY] $hook = @hook.first({ .is-match(|@arg, |%opts) });
    my Hook::Response[ENTRY] $response =
        send-to-hooks($hook, @hook, @arg, |%opts);
}

multi sub send-to-hooks(
    Hook[ENTRY] $hook where .defined,
    Hook[ENTRY] @hook,
    @arg (Entry:D $, Coa:D $, Hodl:D $),
    *%opts (
        Hook:U :applied(@a),
        Entryʹ:D :carry(@c)
    )
    --> Hook::Response[ENTRY]
)
{
    my Entryʹ:D $entryʹ = $hook.apply(|@arg, |%opts);
    my Hook:U @applied = |@a, $hook.WHAT;
    my Entryʹ:D @carry = |@c, $entryʹ;
    my Hook::Response[ENTRY] $response =
        send-to-hooks(@hook, @arg, :@applied, :@carry);
}

multi sub send-to-hooks(
    Hook[ENTRY] $,
    Hook[ENTRY] @,
    @ (Entry:D $, Coa:D $, Hodl:D $),
    *% (
        Hook:U :@applied! where .so,
        Entryʹ:D :@carry! where .so
    )
    --> Hook::Response[ENTRY]
)
{
    my Hash[Entryʹ:D,Hook:U] @made = @applied Z=> @carry;
    my Hook::Response[ENTRY] $response .= new(:@made);
}

multi sub send-to-hooks(
    Hook[ENTRY] $,
    Hook[ENTRY] @,
    @ (Entry:D $, Coa:D $, Hodl:D $),
    *% (
        Hook:U :applied(@),
        Entryʹ:D :carry(@)
    )
    --> Nil
)
{
    die(X::Tantum::Registry::NoHookApplied.new(ENTRY));
}

# --- end ENTRY }}}
# --- LEDGER {{{

multi sub send-to-hooks(
    Hook[LEDGER] @hook,
    @arg (Ledger:D $, Coa:D $, Hodl:D $),
    *%opts (
        Hook:U :applied(@),
        Ledgerʹ:D :carry(@)
    )
    --> Hook::Response[LEDGER]
)
{
    my Hook[LEDGER] $hook = @hook.first({ .is-match(|@arg, |%opts) });
    my Hook::Response[LEDGER] $response =
        send-to-hooks($hook, @hook, @arg, |%opts);
}

multi sub send-to-hooks(
    Hook[LEDGER] $hook where .defined,
    Hook[LEDGER] @hook,
    @arg (Ledger:D $, Coa:D $, Hodl:D $),
    *%opts (
        Hook:U :applied(@a),
        Ledgerʹ:D :carry(@c)
    )
    --> Hook::Response[LEDGER]
)
{
    my Ledgerʹ:D $ledgerʹ = $hook.apply(|@arg, |%opts);
    my Hook:U @applied = |@a, $hook.WHAT;
    my Ledgerʹ:D @carry = |@c, $ledgerʹ;
    my Hook::Response[LEDGER] $response =
        send-to-hooks(@hook, @arg, :@applied, :@carry);
}

multi sub send-to-hooks(
    Hook[LEDGER] $,
    Hook[LEDGER] @,
    @ (Ledger:D $, Coa:D $, Hodl:D $),
    *% (
        Hook:U :@applied! where .so,
        Ledgerʹ:D :@carry! where .so
    )
    --> Hook::Response[LEDGER]
)
{
    my Hash[Ledgerʹ:D,Hook:U] @made = @applied Z=> @carry;
    my Hook::Response[LEDGER] $response .= new(:@made);
}

multi sub send-to-hooks(
    Hook[LEDGER] $,
    Hook[LEDGER] @,
    @ (Ledger:D $, Coa:D $, Hodl:D $),
    *% (
        Hook:U :applied(@),
        Ledgerʹ:D :carry(@)
    )
    --> Nil
)
{
    die(X::Tantum::Registry::NoHookApplied.new(LEDGER));
}

# --- end LEDGER }}}
# --- COA {{{

multi sub send-to-hooks(
    Hook[COA] @hook,
    @arg (Coa:D $, Entry:D $, Hodl:D $),
    *%opts (
        Hook:U :applied(@),
        Coa:D :carry(@)
    )
    --> Hook::Response[COA]
)
{
    my Hook[COA] $hook = @hook.first({ .is-match(|@arg, |%opts) });
    my Hook::Response[COA] $response =
        send-to-hooks($hook, @hook, @arg, |%opts);
}

multi sub send-to-hooks(
    Hook[COA] $hook where .defined,
    Hook[COA] @hook,
    @arg (Coa:D $, Entry:D $, Hodl:D $),
    *%opts (
        Hook:U :applied(@a),
        Coa:D :carry(@c)
    )
    --> Hook::Response[COA]
)
{
    my Coa:D $coa = $hook.apply(|@arg, |%opts);
    my Hook:U @applied = |@a, $hook.WHAT;
    my Coa:D @carry = |@c, $coa;
    my Hook::Response[COA] $response =
        send-to-hooks(@hook, @arg, :@applied, :@carry);
}

multi sub send-to-hooks(
    Hook[COA] $,
    Hook[COA] @,
    @ (Coa:D $, Entry:D $, Hodl:D $),
    *% (
        Hook:U :@applied! where .so,
        Coa:D :@carry! where .so
    )
    --> Hook::Response[COA]
)
{
    my Hash[Coa:D,Hook:U] @made = @applied Z=> @carry;
    my Hook::Response[COA] $response .= new(:@made);
}

multi sub send-to-hooks(
    Hook[COA] $,
    Hook[COA] @,
    @ (Coa:D $, Entry:D $, Hodl:D $),
    *% (
        Hook:U :applied(@),
        Coa:D :carry(@)
    )
    --> Nil
)
{
    die(X::Tantum::Registry::NoHookApplied.new(COA));
}

# --- end COA }}}
# --- HODL {{{

multi sub send-to-hooks(
    Hook[HODL] @hook,
    @arg (Hodl:D $, Entry:D $),
    *%opts (
        Hook:U :applied(@),
        Hodl:D :carry(@)
    )
    --> Hook::Response[HODL]
)
{
    my Hook[HODL] $hook = @hook.first({ .is-match(|@arg, |%opts) });
    my Hook::Response[HODL] $response =
        send-to-hooks($hook, @hook, @arg, |%opts);
}

multi sub send-to-hooks(
    Hook[HODL] $hook where .defined,
    Hook[HODL] @hook,
    @arg (Hodl:D $, Entry:D $),
    *%opts (
        Hook:U :applied(@a),
        Hodl:D :carry(@c)
    )
    --> Hook::Response[HODL]
)
{
    my Hodl:D $hodl = $hook.apply(|@arg, |%opts);
    my Hook:U @applied = |@a, $hook.WHAT;
    my Hodl:D @carry = |@c, $hodl;
    my Hook::Response[HODL] $response =
        send-to-hooks(@hook, @arg, :@applied, :@carry);
}

multi sub send-to-hooks(
    Hook[HODL] $,
    Hook[HODL] @,
    @ (Hodl:D $, Entry:D $),
    *% (
        Hook:U :@applied! where .so,
        Hodl:D :@carry! where .so
    )
    --> Hook::Response[HODL]
)
{
    my Hash[Hodl:D,Hook:U] @made = @applied Z=> @carry;
    my Hook::Response[HODL] $response .= new(:@made);
}

multi sub send-to-hooks(
    Hook[HODL] $,
    Hook[HODL] @,
    @ (Hodl:D $, Entry:D $),
    *% (
        Hook:U :applied(@),
        Hodl:D :carry(@)
    )
    --> Nil
)
{
    die(X::Tantum::Registry::NoHookApplied.new(HODL));
}

# --- end HODL }}}
# --- HOOK {{{

multi sub send-to-hooks(
    Hook[HOOK] @hook,
    @arg (
        Str:D $enter-leave,
        Str:D $class-name,
        Str:D $routine-name,
        Capture:D $capture
    ),
    *%opts (
        Hook:U :applied(@)
    )
    --> Hook::Response[HOOK]
)
{
    my Hook[HOOK] $hook = @hook.first({ .is-match(|@arg, |%opts) });
    my Hook::Response[HOOK] $response =
        send-to-hooks($hook, @hook, @arg, |%opts);
}

multi sub send-to-hooks(
    Hook[HOOK] $hook where .defined,
    Hook[HOOK] @hook,
    @arg (
        Str:D $,
        Str:D $,
        Str:D $,
        Capture:D $
    ),
    *%opts (
        Hook:U :applied(@a)
    )
    --> Hook::Response[HOOK]
)
{
    $hook.apply(|@arg, |%opts);
    my Hook:U @applied = |@a, $hook.WHAT;
    my Hook::Response[HOOK] $response =
        send-to-hooks(@hook, @arg, :@applied);
}

multi sub send-to-hooks(
    Hook[HOOK] $,
    Hook[HOOK] @,
    @ (
        Str:D $,
        Str:D $,
        Str:D $,
        Capture:D $
    ),
    *% (
        Hook:U :@applied! where .so
    )
    --> Hook::Response[HOOK]
)
{
    my Hook:U @made = @applied;
    my Hook::Response[HOOK] $response .= new(:@made);
}

multi sub send-to-hooks(
    Hook[HOOK] $,
    Hook[HOOK] @,
    @ (
        Str:D $,
        Str:D $,
        Str:D $,
        Capture:D $
    ),
    *% (
        Hook:U :applied(@)
    )
    --> Nil
)
{
    die(X::Tantum::Registry::NoHookApplied.new(HOOK));
}

# --- end HOOK }}}

# end method send-to-hooks }}}

# vim: set filetype=perl6 foldmethod=marker foldlevel=0:

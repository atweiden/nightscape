use v6;
use Nightscape::Hook::Action;
use Nightscape::Hook::Trigger;
use Nightscape::Registry;
use Nightscape::Types;
use TXN::Parser::Types;
unit role Nightscape::Hook[HookType $type];
also does Nightscape::Hook::Action[$type];
also does Nightscape::Hook::Trigger[$type];

# p6doc {{{

=begin pod
=head NAME

Nightscape::Hook

=head SYNOPSIS

    my Nightscape::Registry $registry .= new;

    my role Nightscape::Hook::Entry::Posting::All
    {
        also does Nightscape::Hook[POSTING];

        has Str:D $!name is required;
        has Str:D $!description is required;
        has Int:D $!priority = 0;
        has Nightscape::Hook:U @!dependency;

        submethod BUILD(
            Str:D :$!name!,
            Str:D :$!description!,
            Int:D :$!priority!,
            Nightscape::Hook:U :@dependency
            --> Nil
        )
        {
            @!dependency = |@dependency if @dependency;
        }

        method new(
            *%opts (
                Str:D :$name!,
                Str:D :$description!,
                Int:D :$priority!,
                Nightscape::Hook:U :@dependency
            )
            --> Nightscape::Hook::Entry::Posting::All:D
        )
        {
            self.bless(|%opts);
        }

        method name(::?CLASS:D: --> Str:D)
        {
            my Str:D $name = $!name;
        }

        method description(::?CLASS:D: --> Str:D)
        {
            my Str:D $description = $!description;
        }

        method dependency(::?CLASS:D: --> Array[Nightscape::Hook:U])
        {
            my Nightscape::Hook:U @dependency = @!dependency;
        }

        method priority(::?CLASS:D: --> Int:D)
        {
            my Int:D $priority = $!priority;
        }

        method apply(
            Entry::Posting:D $posting,
            Coa:D $c,
            Hodl:D $hodl
            --> Entry::Postingʹ:D
        )
        {
            my COA:D $coa = $registry.send-to-hooks(COA, [$c, $posting]);
            my Entry::Postingʹ $postingʹ .= new(:$coa, :$hodl, :$posting);
        }

        method is-match(
            Entry::Posting:D $posting,
            Coa:D $coa,
            Hodl:D $hodl
            --> Bool:D
        )
        {
            my Bool:D $is-match = True;
        }
    }

    my role Nightscape::Hook::Coa::All
    {
        also does Nightscape::Hook[COA];

        method is-match(
            Entry::Posting:D $posting,
            Coa:D $coa,
            Hodl:D $hodl
            --> Bool:D
        )
        {
            my Bool:D $is-match = True;
        }
    }

    my role Nightscape::Hook::Hook::All
    {
        also does Nightscape::Hook[HOOK];
    }

    # generate hypothetical C<Entry::Posting> for this example
    my Entry::Posting:D $posting = gen-posting();

    # instantiate C<Coa> for this example
    my Coa $coa .= new;

    # instantiate C<Hodl> for this example
    my Hodl $hodl .= new;

=head DESCRIPTION

=begin paragraph
Hooks are the primary means by which Nightscape takes a list of
standard TXN C<Entry>s parsed from a plain-text TXN document, and
feeds it through a pipeline of transformations. This pipeline
produces a I<Chart of Accounts> and other essential accounting
reports.

Hooks allow for closely examining and logging each and every step
a TXN document goes through along the way to an essential report,
leading to increased auditability. Hooks enable a high degree of
insight and fine-grained control over what happens every step of
the way.

Pure functions are to be strived for. Side-effects during pipeline
transformation at the behest of Hooks are strongly discouraged.
Major datapoints, such as I<Chart of Accounts> (C<Coa>) and I<Holdings>
(C<Hodl>) are first class citizens throughout the entirety of the
pipeline, for instance. If and when other data structures become critical
to Nightscape report generation, the key elements of those data structures
should be reigned in similar to how C<Coa> and C<Hodl> are handled.
=end paragraph

=head2 Hooks By Category

=head3 Category: TXN Primitives

=begin paragraph
Category I<TXN Primitives> contains hooks designed to operate on
TXN primitives C<Entry::Posting>, C<Entry>, and C<Ledger>; these
hooks are tasked with generating derivatives C<Entry::Postingʹ> and
C<Entryʹ> respectively. I<Ledger> hooks are TBD.
=end paragraph

=begin item
B<Posting>

I<Posting> hooks are scoped to C<Entry::Posting>s. Each time a new
C<Entry::Posting> is queued for derivative (C<Entry::Postingʹ>)
generation, I<Posting> hooks will be filtered for relevancy and the
actions inscribed in matching hooks executed.

I<Posting> hooks must provide a C<method apply> which accepts as
arguments:

    Entry::Posting:D $posting,
    Coa:D $coa,
    Hodl:D $hodl

and which returns:

    Entry::Postingʹ:D $postingʹ
=end item

=begin item
B<Entry>

I<Entry> hooks are scoped to C<Entry>s. Each time a new C<Entry>
is queued for derivative (C<Entryʹ>) generation, I<Entry> hooks
will be filtered for relevancy and the actions inscribed in matching
hooks executed.

I<Entry> hooks must provide a C<method apply> which accepts as
arguments:

    Entry:D $entry,
    Entry::Postingʹ:D @postingʹ

and which returns:

    Entryʹ:D $entryʹ
=end item

=begin item
B<Ledger>

I<Ledger> hooks are scoped to C<Ledger>s. A C<Ledger> is a fully
assembled TXN document consisting of disparate C<Entry>s. Each time
a new C<Ledger> is queued for instantiation, I<Ledger> hooks will
be filtered for relevancy and the actions inscribed in matching
hooks executed.
=end item

=head3 Category: Derivative Components

=begin paragraph
Category I<Derivative Components> contains hooks designed to operate
on derivative components C<Coa> and C<Hodl>; these hooks are tasked
with generating essential components of derivatives C<Entry::Postingʹ>
and C<Entryʹ>.

For example, a I<Coa> hook could check for a sufficient balance on
an Asset account before crediting the account.
=end paragraph

=begin item
B<Coa>

I<Coa> hooks are scoped to C<Coa>s, aka I<Chart of Accounts>. Each
time a C<Coa> is queued for instantiation (e.g. as part of C<Entryʹ>
or C<Entry::Postingʹ> generation), I<Coa> hooks will be filtered
for relevancy and the actions inscribed in matching hooks executed.

I<Coa> hooks must provide a C<method apply> which accepts as
arguments:

    # an existing Coa
    Coa:D $c,
    Entry::Posting:D $posting

and which returns:

    # a new Coa if applicable
    Coa:D $coa
=end item

=begin item
B<Hodl>

I<Hodl> hooks are scoped to C<Hodl>s. Each time a C<Hodl> is queued
for instantiation (e.g. as part of C<Entryʹ> generation), I<Hodl>
hooks will be filtered for relevancy and the actions inscribed in
matching hooks executed.
=end item

=head2 Category: Meta

=begin item
B<Hook>

I<Hook> hooks are scoped to C<Hook>s. Each time a C<Hook> is queued
for instantiation or application (e.g. C<Hook.apply>), I<Hook> hooks
will be filtered for relevancy and the actions inscribed in matching
hooks executed.

The primary impetus behind I<Hook> hooks is to log which hooks are
firing and when. I<Hook> hooks might also be used to chain hooks
together.
=end item
=end pod

# end p6doc }}}

method name(--> Str:D) {...}
method description(--> Str:D) {...}
# for declaring C<Nightscape::Hook> types needed in registry
method dependency(--> Array[Nightscape::Hook:U]) {...}
# for ordering multiple matching hooks
method priority(--> Int:D) {...}

# method perl {{{

method perl(--> Str:D)
{
    my Str:D $perl =
        sprintf(
            Q{%s.new(%s)},
            perl('type', $type),
            perl('elements', $.name, $.description, $.priority)
        );
}

multi sub perl(
    'type',
    HookType $type
    --> Str:D
)
{
    my Str:D $perl = sprintf(Q{Nightscape::Hook[%s]}, $type);
}

multi sub perl(
    'elements',
    Str:D $name,
    Str:D $description,
    Int:D $priority
    --> Str:D
)
{
    my Str:D $perl =
        sprintf(
            Q{:name(%s), :description(%s), :priority(%s)},
            $name.perl,
            $description.perl,
            $priority.perl
        );
}

# end method perl }}}

# vim: set filetype=perl6 foldmethod=marker foldlevel=0:
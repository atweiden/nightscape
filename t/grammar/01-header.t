use v6;
use lib 'lib';
use Test;
use Nightscape::Parser::Grammar;

plan 4;

# date grammar tests {{{

subtest
{
    my Str @dates =
        Q{2014-01-01},
        Q{2014-01-01T08:48:00Z},
        Q{2014-01-01T08:48:00-07:00},
        Q{2014-01-01T08:48:00.99999-07:00};

    sub is_valid_date(Str:D $date) returns Bool:D
    {
        Nightscape::Parser::Grammar.parse($date, :rule<date>).so;
    }

    ok(
        @dates.grep({is_valid_date($_)}).elems == @dates.elems,
        q:to/EOF/
        ♪ [Grammar.parse($date, :rule<date>)] - 1 of 8
        ┏━━━━━━━━━━━━━┓
        ┃             ┃  ∙ Dates validate successfully, as expected.
        ┃   Success   ┃
        ┃             ┃
        ┗━━━━━━━━━━━━━┛
        EOF
    );
}

# end date grammar tests }}}
# metainfo grammar tests {{{

subtest
{
    my Str @metainfo =
        Q{@tag1 ! @TAG2 !! @TAG5 @bliss !!!!!},
        Q{@"∅" !! @96 !!!!};
    my Str $metainfo_multiline = Q:to/EOF/;
    !!!# comment
    @tag1 # comment
    # comment
    @tag2 # comment
    # another comment
    @tag3#comment
    !!!!!
    EOF
    push @metainfo, $metainfo_multiline.trim;

    sub is_valid_metainfo(Str:D $metainfo) returns Bool:D
    {
        Nightscape::Parser::Grammar.parse($metainfo, :rule<metainfo>).so;
    }

    ok(
        @metainfo.grep({is_valid_metainfo($_)}).elems == @metainfo.elems,
        q:to/EOF/
        ♪ [Grammar.parse($metainfo, :rule<metainfo>)] - 2 of 8
        ┏━━━━━━━━━━━━━┓
        ┃             ┃  ∙ Metainfo validates successfully, as expected.
        ┃   Success   ┃
        ┃             ┃
        ┗━━━━━━━━━━━━━┛
        EOF
    );
}

# end metainfo grammar tests }}}
# description grammar tests {{{

subtest
{
    my Str @descriptions =
        Q{"Transaction\tDescription"},
        Q{"""Transaction\nDescription"""},
        Q{'Transaction Description\'};
        Q{'''Transaction Description\'''};
    my Str $description_multiline = Q:to/EOF/;
    """
    Multiline description line one. \
    Multiline description line two.
    """
    EOF
    push @descriptions, $description_multiline.trim;

    sub is_valid_description(Str:D $description) returns Bool:D
    {
        Nightscape::Parser::Grammar.parse($description, :rule<description>).so;
    }

    ok(
        @descriptions.grep({is_valid_description($_)}).elems ==
            @descriptions.elems,
        q:to/EOF/
        ♪ [Grammar.parse($description, :rule<description>)] - 3 of 8
        ┏━━━━━━━━━━━━━┓
        ┃             ┃  ∙ Descriptions validates successfully, as expected.
        ┃   Success   ┃
        ┃             ┃
        ┗━━━━━━━━━━━━━┛
        EOF
    );
}

# end description grammar tests }}}
# header grammar tests {{{

subtest
{
    my Str @headers;

    push @headers,
        qq{2014-01-01 "I started with 1000 USD" ! @TAG1 @TAG2 # COMMENT\n};

    push @headers, qq{2014-01-02 "I paid Exxon Mobile 10 USD"\n};

    push @headers, qq{2014-01-02\n};

    push @headers, qq{2014-01-03 "I bought ฿0.80000000 BTC for 800 USD#@*!%"\n};

    my Str $header_multiline = Q:to/EOF/;
    2014-05-09# comment
    # comment
    @tag1 @tag2 @tag3 !!!# comment
    # comment
    """ # non-comment
    This is a multiline description of the transaction.
    This is another line of the multiline description.
    """# comment
    #comment
    @tag4#comment
    #comment
    @tag5#comment
    @tag6#comment
    #comment
    !!!# comment here
    EOF

    is(
        Nightscape::Parser::Grammar.parse(@headers[0], :rule<header>).WHAT,
        Match,
        q:to/EOF/
        ♪ [Grammar.parse($header, :rule<header>)] - 4 of 8
        ┏━━━━━━━━━━━━━┓
        ┃             ┃  ∙ Header validates successfully, as expected.
        ┃   Success   ┃
        ┃             ┃
        ┗━━━━━━━━━━━━━┛
        EOF
    );

    is(
        Nightscape::Parser::Grammar.parse(@headers[1], :rule<header>).WHAT,
        Match,
        q:to/EOF/
        ♪ [Grammar.parse($header, :rule<header>)] - 5 of 8
        ┏━━━━━━━━━━━━━┓
        ┃             ┃  ∙ Header validates successfully, as expected.
        ┃   Success   ┃
        ┃             ┃
        ┗━━━━━━━━━━━━━┛
        EOF
    );

    is(
        Nightscape::Parser::Grammar.parse(@headers[2], :rule<header>).WHAT,
        Match,
        q:to/EOF/
        ♪ [Grammar.parse($header, :rule<header>)] - 6 of 8
        ┏━━━━━━━━━━━━━┓
        ┃             ┃  ∙ Header validates successfully, as expected.
        ┃   Success   ┃
        ┃             ┃
        ┗━━━━━━━━━━━━━┛
        EOF
    );

    is(
        Nightscape::Parser::Grammar.parse(@headers[3], :rule<header>).WHAT,
        Match,
        q:to/EOF/
        ♪ [Grammar.parse($header, :rule<header>)] - 7 of 8
        ┏━━━━━━━━━━━━━┓
        ┃             ┃  ∙ Header validates successfully, as expected.
        ┃   Success   ┃
        ┃             ┃
        ┗━━━━━━━━━━━━━┛
        EOF
    );

    is(
        Nightscape::Parser::Grammar.parse($header_multiline, :rule<header>).WHAT,
        Match,
        q:to/EOF/
        ♪ [Grammar.parse($header, :rule<header>)] - 8 of 8
        ┏━━━━━━━━━━━━━┓
        ┃             ┃  ∙ Multiline header validates successfully, as
        ┃   Success   ┃    expected.
        ┃             ┃
        ┗━━━━━━━━━━━━━┛
        EOF
    )
}

# end header grammar tests }}}

# vim: ft=perl6 fdm=marker fdl=0

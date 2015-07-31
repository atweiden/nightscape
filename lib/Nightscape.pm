use v6;
use Nightscape::Entity;
use Nightscape::Entry;
use Nightscape::Types;
unit class Nightscape;

# entities, indexed by name
# may include imported historical wallets and inventory with cost basis
has Nightscape::Entity %.entities{VarName};

# entries, extracted from on disk transaction journal
has Nightscape::Entry @.entries is rw;

# list unique entity names defined in entries
method ls_entity_names(
    Nightscape::Entry:D :@entries! is readonly
) returns Array[VarName:D]
{
    my VarName @entities = .postings[0].account.entity for @entries;
    @entities .= unique;
}

# list entries from on disk transaction journal
multi method ls_entries(
    Str:D :$file!,
    Bool :$sort
) returns Array[Nightscape::Entry]
{
    use Nightscape::Parser;
    if my Match $parsed = Nightscape::Parser.parse(slurp($file))
    {
        my Nightscape::Entry @entries;
        my Nightscape::Entry @entries_included;

        # parse entries from included transaction journals
        push @entries_included, self.ls_entries(:file($_.filename))
            for $parsed.made.grep(Nightscape::Parser::Include);

        # entries, unsorted, with included transaction journals
        @entries = ($parsed.made.grep(Nightscape::Entry), @entries_included);

        # entries, sorted by date ascending then by importance descending
        @entries = @entries.sort({
            $^b.header.important > $^a.header.important
        }).sort({
            .header.date
        }) if $sort;

        @entries;
    }
    else
    {
        die "Sorry, could not parse transaction journal at 「$file」";
    }
}

# filter entries
multi method ls_entries(
    Nightscape::Entry:D :@entries is readonly = @.entries,
    Date :$date,
    Regex :$description,
    Regex :$entity,
    Int :$id,
    Int :$important,
    Regex :$tag
) returns Array[Nightscape::Entry]
{
    my Nightscape::Entry @e = @entries;
    @e = self._ls_entries(:entries(@e), :$date) if $date;
    @e = self._ls_entries(:entries(@e), :$description) if defined $description;
    @e = self._ls_entries(:entries(@e), :$entity) if defined $entity;
    @e = self._ls_entries(:entries(@e), :$id) if $id;
    @e = self._ls_entries(:entries(@e), :$important) if $important;
    @e = self._ls_entries(:entries(@e), :$tag) if defined $tag;
    @e;
}

# list entries by date
multi method _ls_entries(
    Nightscape::Entry:D :@entries! is readonly,
    Date:D :$date!
) returns Array[Nightscape::Entry]
{
    my Nightscape::Entry @e = @entries.grep({ .header.date ~~ $date });
}

# list entries by entity
multi method _ls_entries(
    Nightscape::Entry:D :@entries! is readonly,
    Regex:D :$entity!
) returns Array[Nightscape::Entry]
{
    my Nightscape::Entry @e = @entries.grep({
        .postings[0].account.entity ~~ $entity
    });
}

# instantiate entity
method mkentity(VarName:D :$entity_name!, Bool :$force)
{
    sub init()
    {
        # instantiate new entity
        %!entities{$entity_name} = Nightscape::Entity.new(:$entity_name);
    }

    # was :force arg passed?
    if $force
    {
        # overwrite existing entity with new entity
        init();
    }
    # does entity exist?
    elsif %.entities{$entity_name}
    {
        # error: entity exists, can't overwrite
        die "Sorry, can't mkentity 「$entity_name」: entity exists.";
    }
    else
    {
        # entity does not exist, instantiate new entity
        init();
    }
}

# vim: ft=perl6

use v6;
use lib 'lib';
use Test;
use Nightscape;
use Nightscape::Config;
use Nightscape::Types;

plan 2;

our $conf = Nightscape::Config.new;

# prepare assets and entities for transaction journal parsing
{
    # parse TOML config
    my %toml;
    try
    {
        use TOML;
        my $toml_text = slurp $conf.config_file
            or die "Sorry, couldn't read config file: ", $conf.config_file;
        %toml = %(from-toml $toml_text);
        CATCH
        {
            say "Sorry, couldn't parse TOML syntax in config file: ",
                $conf.config_file;
        }
    }

    # set base currency
    my $base_currency_found = %toml<base-currency>;
    if $base_currency_found
    {
        $conf.base_currency = %toml<base-currency>;
    }

    # set base costing method
    my $base_costing_found = %toml<base-costing>;
    if $base_costing_found
    {
        $conf.base_costing = %toml<base-costing>;
    }

    # populate asset settings
    my %assets_found = Nightscape::Config.detoml_assets(%toml);
    if %assets_found
    {
        for %assets_found.kv -> $asset_code, $asset_data
        {
            $conf.assets{$asset_code} = Nightscape::Config.gen_settings(
                :$asset_code,
                :$asset_data
            );
        }
    }

    # populate entity settings
    my %entities_found = Nightscape::Config.detoml_entities(%toml);
    if %entities_found
    {
        for %entities_found.kv -> $entity_name, $entity_data
        {
            $conf.entities{$entity_name} = Nightscape::Config.gen_settings(
                :$entity_name,
                :$entity_data
            );
        }
    }
}

my Str $file = "examples/sample.transactions";
my Nightscape::Entry @entries;

if $file.IO.e
{
    @entries = Nightscape.ls_entries(:$file, :sort);
}
else
{
    die "Sorry, couldn't locate file: $file";
}

{
    # make entity Personal
    my Nightscape::Entity $entity_personal = Nightscape::Entity.new(
        :entity_name("Personal")
    );

    # get entries by entity Personal
    my Nightscape::Entry @entries_by_entity_personal = Nightscape.ls_entries(
        :@entries,
        :entity(/Personal/)
    );

    # generate transactions from entries by entity Personal
    my Nightscape::Transaction @transactions_by_entity_personal;
    push @transactions_by_entity_personal,
        $entity_personal.gen_transaction(:entry($_))
            for @entries_by_entity_personal;

    # execute transactions of entity Personal
    $entity_personal.transact(:transaction($_))
        for @transactions_by_entity_personal;

    # check that the balance of entity Personal's ASSETS is -837.84 USD
    is(
        $entity_personal.wallet{ASSETS}.get_balance(:asset_code("USD")),
        -837.84,
        q:to/EOF/
        ♪ [get_balance] - 1 of 2
        ┏━━━━━━━━━━━━━┓
        ┃             ┃  ∙ Passed argument of "USD" returns -837.84,
        ┃   Success   ┃    as expected.
        ┃             ┃
        ┗━━━━━━━━━━━━━┛
        EOF
    );

    # check that the balance of entity Personal's ASSETS is 1.91111111 BTC
    is(
        $entity_personal.wallet{ASSETS}.get_balance(:asset_code("BTC")),
        1.91111111,
        q:to/EOF/
        ♪ [get_balance] - 2 of 2
        ┏━━━━━━━━━━━━━┓
        ┃             ┃  ∙ Passed argument of "BTC" returns 1.91111111,
        ┃   Success   ┃    as expected.
        ┃             ┃
        ┗━━━━━━━━━━━━━┛
        EOF
    );
}

# vim: ft=perl6

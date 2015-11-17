use v6;
use Nightscape::Config::Asset;
use Nightscape::Types;
unit class Nightscape::Config::Entity;

# entity name
has VarName $.entity_name is required;

# entity base asset costing method
has Costing $.base_costing;

# entity base currency
has AssetCode $.base_currency;

# open date range
has Range $.open;

# entity-specific asset settings parsed from config, indexed by asset code
has Nightscape::Config::Asset %.assets{AssetCode};

# vim: ft=perl6

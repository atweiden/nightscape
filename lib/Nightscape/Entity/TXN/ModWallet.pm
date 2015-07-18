use v6;
use Nightscape::Types;
use UUID;
unit class Nightscape::Entity::TXN::ModWallet;

# causal entry's uuid
has UUID $.entry_uuid;

# causal posting's uuid
has UUID $.posting_uuid;

# account
has Silo $.silo;
has VarName @.subwallet;

# amount
has AssetCode $.asset_code;
has DecInc $.decinc;
has Quantity $.quantity;

# xe
has AssetCode $.xe_asset_code;
has Quantity $.xe_asset_quantity;

# vim: ft=perl6
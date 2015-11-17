use v6;
use Nightscape::Entity::TXN::ModHolding;
use Nightscape::Entity::TXN::ModWallet;
use Nightscape::Types;
unit class Nightscape::Entity::TXN;

# parent entity
has VarName $.entity is required;

# causal EntryID
has EntryID $.entry_id is required;

# transaction drift (error margin)
has FatRat $.drift = self.get_drift.keys[0];

# holdings acquisitions and expenditures indexed by asset, in entry
has Nightscape::Entity::TXN::ModHolding %.mod_holdings{AssetCode};

# wallet balance modification instructions per posting, in entry
has Nightscape::Entity::TXN::ModWallet @.mod_wallet is required;

# calculate drift (error margin) present in this TXN's ModWallet array
method get_drift(
    Nightscape::Entity::TXN::ModWallet:D :@mod_wallet is readonly =
        @.mod_wallet
) returns Hash[Hash[FatRat:D,AcctName:D],FatRat:D]
{
    my Hash[FatRat:D,AcctName:D] %drift{FatRat:D};
    my FatRat:D $drift = FatRat(0.0);
    my FatRat:D %raw_value_by_acct_name{AcctName:D};

    # Assets + Expenses = Income + Liabilities + Equity
    my Int %multiplier{Silo} =
        ::(ASSETS) => 1,
        ::(EXPENSES) => 1,
        ::(INCOME) => -1,
        ::(LIABILITIES) => -1,
        ::(EQUITY) => -1;

    for @mod_wallet -> $mod_wallet
    {
        # get AcctName
        my AcctName $acct_name = $mod_wallet.get_acct_name;

        # get Silo
        my Silo $silo = $mod_wallet.silo;

        # get subtotal raw value
        my FatRat $raw_value = $mod_wallet.get_raw_value;

        # add subtotal raw value to causal acct name index
        %raw_value_by_acct_name{$acct_name} += $raw_value;

        # add subtotal raw value to drift
        $drift += $raw_value * %multiplier{$silo};
    }

    %drift{$drift} = $%raw_value_by_acct_name;
    %drift;
}

# vim: ft=perl6

use v6;
use Nightscape::Entity::Holding::Basis;
use Nightscape::Entity::Holding::Taxes;
use Nightscape::Types;
use UUID;
unit class Nightscape::Entity::Holding;

# asset code
has AssetCode $.asset_code;

# average cost of units held
has Price $.avco;

# cost basis of units held (date, price, quantity)
has Nightscape::Entity::Holding::Basis @.basis;

# tax consequences indexed by causal entry's uuid
has Array[Nightscape::Entity::Holding::Taxes] %.taxes{UUID};

# increase entity's holdings
method acquire(
    UUID :$uuid!,
    Date :$date!,
    Price :$price!,
    Quantity :$quantity! where * > 0
)
{
    # add to holdings
    push @!basis, Nightscape::Entity::Holding::Basis.new(
        :$uuid,
        :$date,
        :$price,
        :$quantity
    );

    # update average cost
    $!avco = self.gen_avco;
}

# decrease entity's holdings via AVCO/FIFO/LIFO inventory costing method
method expend(
    AssetCode :$asset_code!,
    UUID :$uuid!,
    Costing :$costing!,
    Price :$price!,
    AssetCode :$acquisition_price_asset_code!,
    Quantity :$quantity! where * > 0
)
{
    # check for sufficient unit quantity of asset in holdings
    unless self.in_stock($quantity)
    {
        die qq:to/EOF/;
        Sorry, cannot expend: found insufficient quantity of asset
        in holdings.
        EOF
    }

    # find array indices of Basis with sufficient units to expend,
    # starting from the beginning of the list for AVCO/FIFO, end of
    # the list for LIFO, along with the number of units to expend per
    # array index
    my Quantity @targets = self.find_targets(:$costing, :$quantity);

    # deplete units in targeted basis lots
    # has side effect of recording capital gains/losses to %.taxes
    sub rmtargets(:@targets!) # Constraint type check failed for parameter '%targets'
    {
        # for each @.basis lot target index $i and associated quantity $q
        for @targets.pairs.kv -> $i, $q
        {
            # necessary since array can contain skipped basis lot index targets
            unless $q.value
            {
                next;
            }

            # get value of $q pair
            my Quantity $qty = $q.value;

            # get scalar container of basis lot
            my Nightscape::Entity::Holding::Basis $basis := @!basis[$i];

            # try decreasing units by quantity
            $basis.deplete(
                :$uuid,
                :quantity($qty),
                :acquisition_price($basis.price),
                :$acquisition_price_asset_code,
                :avco_at_expenditure($.avco)
            );

            # for calculating capital gains/losses
            my Rat $d;

            # AVCO inventory valuation method?
            if $costing ~~ AVCO
            {
                # (expend price - average cost) * quantity expended
                $d = ($price - $.avco) * $qty;
            }
            # FIFO or LIFO inventory valuation method?
            elsif $costing ~~ FIFO or $costing ~~ LIFO
            {
                # (expend price - acquisition price) * quantity expended
                $d = ($price - $basis.price) * $qty;
            }

            if $d > 0
            {
                # record capital gains
                my Quantity $capital_gains = $d.abs;
                push %!taxes{$uuid}, Nightscape::Entity::Holding::Taxes.new(
                    :$uuid,
                    :acquisition_price($basis.price),
                    :$acquisition_price_asset_code,
                    :avco_at_expenditure($.avco),
                    :$capital_gains,
                    :quantity_expended($qty),
                    :quantity_expended_asset_code($.asset_code)
                );
            }
            elsif $d < 0
            {
                # record capital losses
                my Quantity $capital_losses = $d.abs;
                push %!taxes{$uuid}, Nightscape::Entity::Holding::Taxes.new(
                    :$uuid,
                    :acquisition_price($basis.price),
                    :$acquisition_price_asset_code,
                    :avco_at_expenditure($.avco),
                    :$capital_losses,
                    :quantity_expended($qty),
                    :quantity_expended_asset_code($.asset_code)
                );
            }
            else
            {
                # no gains or losses to report
            }
        }
    }

    # expend targets
    rmtargets(:@targets);
}

# identify unit quantities to be expended, indexed by @.basis array index
method find_targets(
    Costing :$costing!,
    Quantity :$quantity! where * > 0
) returns Array[Quantity]
{
    # basis lots, to be reversed when LIFO costing method is used
    my Nightscape::Entity::Holding::Basis @basis;
    $costing ~~ LIFO ?? (@basis = @.basis.reverse) !! (@basis = @.basis);

    # units to expend, indexed by @.basis array index
    my Quantity @targets;

    # @.basis array index count
    my Int $count = 0;

    # running total
    my Quantity $remaining = $quantity;

    # fill in targets as needed
    for @basis -> $basis
    {
        # are more units still needed?
        if $remaining > 0
        {
            # is the quantity of units in this basis lot less than
            # the amount of units still needed?
            if $remaining >= $basis.quantity
            {
                # target all units in this basis lot
                @targets[$count] = $basis.quantity;

                # subtract all units in this basis lot from remaining
                $remaining -= $basis.quantity;

                # increment @.basis array index if remaining targets, else break
                $remaining > 0 ?? $count++ !! last;
            }
            else
            {
                # target only the units necessary from this basis lot
                @targets[$count] = $remaining;

                # no more units are remaining
                $remaining -= $remaining;
                last;
            }
        }
        else
        {
            # no more units needed
            last;
        }
    }

    @targets;
}

# calculate average cost of current holdings
method gen_avco() returns Price
{
    # calculate total value of units held
    my Price $value = self.get_total_value;

    # calculate total quantity of units held
    my Quantity $quantity = self.get_total_quantity;

    # weighted average cost
    $value / $quantity;
}

# calculate total quantity of units held
method get_total_quantity(
    Nightscape::Entity::Holding::Basis :@basis is readonly = @.basis
) returns Quantity
{
    my Quantity $quantity = [+] (.quantity for @basis);
    $quantity;
}

# calculate total value of units held
# by default assumes price paid at acquisition
# pass :market for market price (NYI)
method get_total_value(
    Nightscape::Entity::Holding::Basis :@basis is readonly = @.basis,
    Bool :$market
) returns Price
{
    my Price @value;
    for @basis -> $b
    {
        my Price $p = $b.price;
        my Quantity $q = $b.quantity;
        my Price $v = $p * $q;
        push @value, $v;
    }
    my Price $value = [+] @value;
    $value;
}

# check for sufficient unit quantity of asset in holdings
method in_stock(Quantity $quantity) returns Bool
{
    $quantity <= self.get_total_quantity ?? True !! False;
}

# vim: ft=perl6

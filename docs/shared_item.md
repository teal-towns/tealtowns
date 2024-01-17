Shared items are (possibly) passed through generations of shared owners.

We could allow multiple funders (investors), but that requires more fees and risk with the transfer of money to make the initial purchase. So we will allow people to handle the purchase on their own, outside the platform and we will work with only 1 purchaser.

## Lifecycle (one generation)

1. Someone posts an item they own or want to own; shared item starts as `available`.
2. Owners pledge (deposit down payment) to co-own. If not already owned, an investor is also needed to buy it. Once there are enough shared owners, if not already owned, the item goes to `purchasing` while the investor buys. The investor gets the down payments from the co-owners.
    a. Money deposits are stored in the user's account and allocated; if the purchase does not happen (not enough owners), they can use the money for something else (or withdraw it).
3. Once purchased, item goes to `owned` and monthly payments start (the next 1st of the month) until the item is paid off. Each month the payments are distributed to pay back the investor (puchaser).

## Payments

There are 3 types of transactions, generally in the following order:
1. 3rd party (e.g. Stripe) payment processing
2. Money movement (within the platform, but no actual real money changes any bank accounts - just database values for balances are updated)
3. Withdrawals (e.g. ACH)

The lead investor pays for the item outside the platform, and this is paid back over time.
Down payments and monthly payments are charged to payees (co-owners) and moved onto the platform (our bank account) and the investor(s) balances are increased accordingly. Anyone who has a positive balance can withdraw their money as a separate transaction.
In other words, all payments go through our bank as a central system; there are no direct peer to peer payments, so each "payment" means 0 or 1 real money (bank acount) changes. People pay (e.g. Stripe) into the platform (our bank), and then separately can widthdrawl (e.g. ACH) from the platform.

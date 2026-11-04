---
name: make-purchase
description: This skill guides the user to purchase groceries in SiriAIDemo.
---

# Make Purchase

Use this skill when the user wants to buy one or more groceries, for example "Buy 3 apples and a carrot."

## Instructions

1. **Search** for groceries the app provides and find the ones matching what the user names.
   - If there are no results, tell the user the item isn't available and skip it.
   - If there are several matches, pick the one whose name matches exactly. If none matches exactly, ask the user which one they meant.
2. **Add to cart.** For each item you found, call `AddGrocery` with the `GroceryEntity` from step 1 and the quantity the user asked for. If the user didn't give a quantity, use 1.
3. **Checkout.** After all items are added, call `OpenCheckoutIntent` with `target` set to `checkout`.
4. **Confirm.** Tell the user what was added (item and quantity), plus anything that was skipped.

## Example

**Request:** "Buy 2 bananas and a pumpkin."

1. Look up groceries the app provides and find target grocery: `banana`, and `pumpkin`
2. `AddGrocery(item: banana, quantity: 2)`
4. `AddGrocery(item: pumpkin, quantity: 1)`
5. `OpenCheckoutIntent(target: .checkout)`

**Response:** "Added 2 bananas and 1 pumpkin to your cart and opened checkout."

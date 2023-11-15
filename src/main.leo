
program token.aleo {
    //accounts have tokens
    mapping account:address => u64;

    //record
    record token {
        owner: address,
        amount: u64,
    }

    //we can mint, transfer token but there are public and private
    //minting public first
    transition mint_public(public receiver:address, public amount:u64) {
        
        return then finalize(receiver, amount);
    }

    finalize mint_public(public receiver:address, public amount:u64) {

        // remember we have mapping at the beginning. First two params mean account[receiver]
        let receiver_amount:u64 = Mapping::get_or_use(account,receiver ,0u64 );
        // Sum the account balance
        Mapping::set(account, receiver, receiver_amount+amount);
    }

    transition mint_private(receiver:address, amount:u64) -> token {
        return token {
            owner:receiver,
            amount:amount
        };
        //created record for token with amount of reciever 
        //didn't set anything onchain or publicly so we don't need finalize function


    }

    // now we send some funds to the other wallets
    transition transfer_public(public receiver:address, public amount:u64) {
        return then finalize(self.caller, receiver, amount);
    
    }

    finalize transfer_public(public sender:address, public receiver:address, public amount:u64) {
        //increase amount of sender, decrease amount of sender
        let sender_amount:u64 = Mapping::get_or_use(account, sender, 0u64);
        Mapping::set(account, sender, sender_amount - amount);

        let receiver_amount:u64 = Mapping::get_or_use(account, receiver, 0u64);
        Mapping::set(account, receiver, receiver_amount + amount);
    }

    // we put 2 tokens bc we're changing record of sender and receiver
    //we use sender of type token because sender address is private
    transition transfer_private(sender:token, receiver:address, amount:u64) -> (token,token) {
        let difference:u64 = sender.amount - amount;

        let remaining:token = token{
            owner:sender.owner,
            amount:difference
        };

        let transferred:token = token{
            owner:receiver,
            amount:amount
        };

        return (remaining, transferred);
        //What we have done is UTXO-esque
        // You give some amount of money that someone took
        //Set sender amount to remaining amount, set receiver amount to service fee
    }

    //we can also send some amount of money to private to public or vice versa


    transition private_to_public(sender:token, public receiver:address, public amount:u64) -> token {
        //sending tokens from private to public - sender remains private, receiver is public
        let difference:u64 = sender.amount - amount;
        let remaining:token = token{
            owner:sender.owner,
            amount:difference
        };

        return remaining then finalize(receiver,amount);

    }

    finalize private_to_public(public receiver:address, public amount:u64) {
        //set receiver amount on-chain
        let receiver_amount:u64 = Mapping::get_or_use(account, receiver, 0u64);
        Mapping::set(account, receiver, receiver_amount + amount);
    }

    transition public_to_private(public receiver:address, public amount:u64) -> token {
        let transferred:token = token {
            owner:receiver,
            amount:amount
        };

        return transferred then finalize(self.caller, amount);
    }

    finalize public_to_private(public sender:address, public amount:u64) {
        let sender_amount:u64 = Mapping::get_or_use(account, sender, 0u64);
        Mapping::set(account, sender, sender_amount - amount);

    }
}

//program id and json should match 

//to run leo run mint_public *address* *amount*
//

// program token.aleo {
//     // On-chain storage of an `account` map, with `address` as the key,
//     // and `u64` as the value.
//     mapping account: address => u64;

//     record token {
//         // The token owner.
//         owner: address,
//         // The token amount.
//         amount: u64,
//     }

//     /* Mint */

//     // The function `mint_public` issues the specified token amount for the token receiver publicly on the network.
//     transition mint_public(public receiver: address, public amount: u64) {
//         // Mint the tokens publicly by invoking the computation on-chain.
//         return then finalize(receiver, amount);
//     }

//     finalize mint_public(public receiver: address, public amount: u64) {
//         // Increments `account[receiver]` by `amount`.
//         // If `account[receiver]` does not exist, it will be created.
//         // If `account[receiver] + amount` overflows, `mint_public` is reverted.
//         let current_amount: u64 = Mapping::get_or_use(account, receiver, 0u64);
//         Mapping::set(account, receiver, current_amount + amount);
//     }

//     // The function `mint_private` initializes a new record with the specified amount of tokens for the receiver.
//     transition mint_private(receiver: address, amount: u64) -> token {
//         return token {
//             owner: receiver,
//             amount: amount,
//         };
//     }

//     /* Transfer */
//     transition transfer_public(public receiver: address, public amount: u64) {
//         // Transfer the tokens publicly, by invoking the computation on-chain.
//         return then finalize(self.caller, receiver, amount);
//     }

//     finalize transfer_public(public sender: address, public receiver: address, public amount: u64) {
//         // Decrements `account[sender]` by `amount`.
//         // If `account[sender]` does not exist, it will be created.
//         // If `account[sender] - amount` underflows, `transfer_public` is reverted.
//         let sender_amount: u64 = Mapping::get_or_use(account, sender, 0u64);
//         Mapping::set(account, sender, sender_amount - amount);
//         // Increments `account[receiver]` by `amount`.
//         // If `account[receiver]` does not exist, it will be created.
//         // If `account[receiver] + amount` overflows, `transfer_public` is reverted.
//         let receiver_amount: u64 = Mapping::get_or_use(account, receiver, 0u64);
//         Mapping::set(account, receiver, receiver_amount + amount);
//     }

//     // The function `transfer_private` sends the specified token amount to the token receiver from the specified token record.
//     transition transfer_private(sender: token, receiver: address, amount: u64) -> (token, token) {
//         // Checks the given token record has sufficient balance.
//         // This `sub` operation is safe, and the proof will fail if an overflow occurs.
//         // `difference` holds the change amount to be returned to sender.
//         let difference: u64 = sender.amount - amount;

//         // Produce a token record with the change amount for the sender.
//         let remaining: token = token {
//             owner: sender.owner,
//             amount: difference,
//         };

//         // Produce a token record for the specified receiver.
//         let transferred: token = token {
//             owner: receiver,
//             amount: amount,
//         };

//         // Output the sender's change record and the receiver's record.
//         return (remaining, transferred);
//     }

//     // The function `transfer_private_to_public` turns a specified token amount from a token record into public tokens for the specified receiver.
//     // This function preserves privacy for the sender's record, however it publicly reveals the token receiver and the token amount.
//     transition transfer_private_to_public(sender: token, public receiver: address, public amount: u64) -> token {
//         // Checks the given token record has a sufficient token amount.
//         // This `sub` operation is safe, and the proof will fail if an underflow occurs.
//         // `difference` holds the change amount for the caller.
//         let difference: u64 = sender.amount - amount;

//         // Produces a token record with the change amount for the caller.
//         let remaining: token = token {
//             owner: sender.owner,
//             amount: difference,
//         };

//         // Output the sender's change record.
//         // Increment the token amount publicly for the token receiver.
//         return remaining then finalize(receiver, amount);
//     }

//     finalize transfer_private_to_public(public receiver: address, public amount: u64) {
//         // Increments `account[receiver]` by `amount`.
//         // If `account[receiver]` does not exist, it will be created.
//         // If `account[receiver] + amount` overflows, `transfer_private_to_public` is reverted.
//         let current_amount: u64 = Mapping::get_or_use(account, receiver, 0u64);
//         Mapping::set(account, receiver, current_amount + amount);
//     }

//     // The function `transfer_public_to_private` turns a specified token amount from `account` into a token record for the specified receiver.
//     // This function preserves privacy for the receiver's record, however it publicly reveals the caller and the specified token amount.
//     transition transfer_public_to_private(public receiver: address, public amount: u64) -> token {
//         // Produces a token record for the token receiver.
//         let transferred: token = token {
//             owner: receiver,
//             amount: amount,
//         };

//         // Output the receiver's record.
//         // Decrement the token amount of the caller publicly.
//         return transferred then finalize(self.caller, amount);
//     }

//     finalize transfer_public_to_private(public sender: address, public amount: u64) {
//         // Decrements `account[sender]` by `amount`.
//         // If `account[sender]` does not exist, it will be created.
//         // If `account[sender] - amount` underflows, `transfer_public_to_private` is reverted.
//         let current_amount: u64 = Mapping::get_or_use(account, sender, 0u64);
//         Mapping::set(account, sender, current_amount - amount);
//     }

// }

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.4.22 <0.7.0;

contract NGObid {
    // Parameters of the auction. Times are either
    // absolute unix timestamps (seconds since 1970-01-01)
    // or time periods in seconds.
    
    struct Bidder {
        bool bid;  // if true, that person already voted
        uint bid_amount;   // index of the voted proposal
    }
    
    
    address public chairperson;

    mapping(address => Bidder) public bidders;

    
    
    address payable public beneficiary;
    uint public auctionEndTime;

    // Current state of the auction.
    address public lowestBidder;
    uint public lowestBid;



    // Set to true at the end, disallows any change.
    // By default initialized to `false`.
    bool ended;

    // Events that will be emitted on changes.
    event LowestBidDecreased(address bidder, uint amount);
    event AuctionEnded(address winner, uint amount);

    // The following is a so-called natspec comment,
    // recognizable by the three slashes.
    // It will be shown when the user is asked to
    // confirm a transaction.

    /// Create a simple auction with `_biddingTime`
    /// seconds bidding time on behalf of the
    /// beneficiary address `_beneficiary`.
    constructor(
        uint _biddingTime,
        address payable _beneficiary,
        address _chairperson
    ) public {
        beneficiary = _beneficiary;
        chairperson = _chairperson;
        auctionEndTime = now + _biddingTime;
    }

    /// Bid on the auction with the value sent
    /// together with this transaction.
    /// The value will only be refunded if the
    /// auction is not won.
    
    function giveRightToBid(address bidder) public {
        require(
            msg.sender == chairperson,
            "Only chairperson can give right to bid."
        );
        require(
            !bidders[bidder].bid,
            "The bidder already bid."
        );

    }    
    
    
    
    function bid() public payable {
        Bidder storage sender = bidders[msg.sender];
        require(!sender.bid, "Already bid.");
        sender.bid = true;
        // No arguments are necessary, all
        // information is already part of
        // the transaction. The keyword payable
        // is required for the function to
        // be able to receive Ether.

        // Revert the call if the bidding
        // period is over.
        require(
            now <= auctionEndTime,
            "Auction already ended."
        );

        // If the bid is not higher, send the
        // money back.
        require(
            msg.value <= lowestBid,
            "There already is a lower bid."
        );

        lowestBidder = msg.sender;
        lowestBid = msg.value;
        emit LowestBidDecreased(msg.sender, msg.value);
    }



    /// End the auction and send the highest bid
    /// to the beneficiary.
    function auctionEnd() public {
        // It is a good guideline to structure functions that interact
        // with other contracts (i.e. they call functions or send Ether)
        // into three phases:
        // 1. checking conditions
        // 2. performing actions (potentially changing conditions)
        // 3. interacting with other contracts
        // If these phases are mixed up, the other contract could call
        // back into the current contract and modify the state or cause
        // effects (ether payout) to be performed multiple times.
        // If functions called internally include interaction with external
        // contracts, they also have to be considered interaction with
        // external contracts.

        // 1. Conditions
        require(now >= auctionEndTime, "Auction not yet ended.");
        require(!ended, "auctionEnd has already been called.");

        // 2. Effects
        ended = true;
        emit AuctionEnded(lowestBidder, lowestBid);

        // 3. Interaction
        beneficiary.transfer(lowestBid);
    }
}

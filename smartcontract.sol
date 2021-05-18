{
    // Parameters of the auction. Times are either
    // absolute unix timestamps (seconds since 1970-01-01)
    // or time periods in seconds.
    
    struct Bidder {
        bool bid;  // if true, that person already bid
        uint bid_amount;   // the bid amount associated with a particular bidder
    }
    
    
    address payable public chairperson; //this is the person who has the authority to grant bidding access to bidders and release funds upon delivery of product

    mapping(address => Bidder) public bidders;

    
    
    
    uint public auctionEndTime;

    // Current state of the auction.
    address payable public lowestBidder;
    uint public lowestBid = 20; //set the minimum bid to 20 otherwise it would be zero. need a better way to do this
    uint public deliveryCode;
    bool public productReceived;



    // Set to true at the end, disallows any change.
    // By default initialized to `false`.
    bool ended;

    // Events that will be emitted on changes.
    event LowestBidDecreased(address bidder, uint amount);
    event AuctionEnded(address winner, uint amount);
    event DeliveryCodeProvided (address lowestBidder, uint deliveryCode);

 /// this initiates the contract with
 /// _biddingTime and assigning the chairperson
    constructor(
        uint _biddingTime,
        address  payable _chairperson
    ) public payable {
        chairperson = _chairperson;
        auctionEndTime = now + _biddingTime;
    }

    
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
    
    
    function bid(uint user_bid) public payable {
        Bidder storage sender = bidders[msg.sender];
        require(!sender.bid, "Already bid.");
        sender.bid = true;

        require(
            now <= auctionEndTime,
            "Auction already ended."
        );
        

        // If the bid is not lower, don't accept
        // the bid.
        require(
            user_bid <= lowestBid,
            "There already is a lower bid."
        );

        lowestBidder = msg.sender;
        lowestBid = user_bid;
        emit LowestBidDecreased(msg.sender, user_bid);
    }



    /// End the auction and send the and announce the winning bid
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


    }
    
    ///the winning bidder will provide a delivery code
    function provideDeliveryCode(uint deliveryCode1) public {
        
        require(
            msg.sender == lowestBidder,
            "Only the winning bidder can send the product"
            );
            
        deliveryCode = deliveryCode1;
        emit DeliveryCodeProvided(lowestBidder,deliveryCode);    
        
    }
    
    /// the chairperson will check that the delivered product matches the delivery code
    /// an updated smart contract will also distribute the funds within this function. for now seperate functions
    function productDelivered(uint chairpersoninput) public payable {
        
        require(
            msg.sender == chairperson,
            "Only chairperson can approve payment upon delivery."
        );
        
        require (
            deliveryCode == chairpersoninput,
            "Product code does not equal the one provided"
        );
        
        
        productReceived = true;
                
        
    }
    
    function deliverPayment() public payable {
        
        lowestBidder.transfer(lowestBid);
        chairperson.transfer(address(this).balance);
    }
    
    
}

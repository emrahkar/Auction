//SPDX-License-Identifier: MIT

pragma solidity >= 0.5.0 <0.9.0;

contract Auction {
    
    address payable public owner;
    uint public startBlock;
    uint public endBlock;
    string public IpfsHashInfo;

    enum State {Started, Running, Ended, Cancelled}
    State public auctionState;

    uint public highestBindingBid;
    address payable public highestBidder;

    mapping(address => uint) public bids;
    uint bidIncrement;

    constructor(address) {

        //beneficiary will be the msg.sender after auction is completed and will start the bid;
        owner = payable(msg.sender);   
        
        //auction is running once the contract is deployed;
        auctionState = State.Running;
        
        //current block during the deployment;
        startBlock = block.number;
        
        //acution is going to take a week , number of blocks in a week is 40320;(one block every 15 sec);
        endBlock = block.number + 40320;    
        
        //product information for the auction;
        IpfsHashInfo = "";   
        
        //wei;
        bidIncrement = 100;  

    }

    modifier notOwner(){
        require(msg.sender != owner);
        _;
    }

    modifier starting(){
        require(block.number >= startBlock);
        _;
    }

    modifier ending(){
        require(block.number <= endBlock);
        _;
    }

    modifier onlyOwner(){
        require(msg.sender == owner);
        _;
    }

    function min(uint a, uint b) pure internal returns(uint){
        if(a <= b){
            return a;
        }else{
            return b;
        }
        
    }
   
    function cancelAuction() public onlyOwner{
        auctionState = State.Cancelled;
    }
    
    function publicBid() public payable notOwner starting ending {
        require(msg.value >= 100);
        require(auctionState == State.Running);

        uint currentBid = bids[msg.sender] + msg.value;
        require(currentBid > highestBindingBid);

        bids[msg.sender] = currentBid;

        if(currentBid <= bids[highestBidder]){
            highestBindingBid = min(currentBid + bidIncrement, bids[highestBidder]);

        }else{
            highestBindingBid = min(currentBid, bids[highestBidder] + bidIncrement);
            highestBidder = payable(msg.sender);
        }
        
    }

    function finalizeAuction() public {
        require(auctionState == State.Cancelled || block.number >= endBlock); //only works if contract is cancelled or the auction is over
        require(msg.sender == owner || bids[msg.sender] >0); // owner or any participant can finalize the Auction

        address payable recipient;
        uint value;

        if(auctionState == State.Cancelled){   //if Auction is cancelled everyine receiveds their money back
            recipient = payable(msg.sender);   
            value = bids[msg.sender];
        }else{
            if(msg.sender == owner){ //if Auction is over and contract creator is the message sender, it receives the highest binding bid;
                recipient = owner;
                value = highestBindingBid;
            }else{
                if(msg.sender == highestBidder){ //if Auction is over and contract creator is the Auction winner, receives back the gap;
                    recipient = highestBidder;
                    value = bids[highestBidder] - highestBindingBid;
                }else{
                    recipient = payable(msg.sender); //if Auction is over and contract creator is the Auction winner;
                    value = bids[msg.sender];
                }
            }
        }
        bids[recipient] = 0; // so no one can finalize the auction more than once to get more money;
        recipient.transfer(value); // related value is transferred to the person who finalized the Auction;
    }
    
}

//This code is a project from Master Ethereum and Solidity Course, no financial advice;
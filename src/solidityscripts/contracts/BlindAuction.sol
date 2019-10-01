contract BlindAuction {
  uint private creationTime = now;
  
  

  //States definition
  enum States {
    InTransition,
    ABB, 
    RB,  
    C, 
    F 
  }
  States private state = States.ABB;
  //Insert variable definitions

  struct Bid { 
    bytes32 blindedBid;        
    uint deposit;    
  }  
  mapping(address => Bid[]) private bids;  
  mapping(address => uint)  private pendingReturns;  
  address private highestBidder;  
  uint private highestBid;
//Transitions 
function bid (    bytes32 blindedBid) 
 payable  
{
    require(state == States.ABB);
    
    //State change
    state = States.InTransition;
    //Actions
       bids[msg.sender].push(Bid({
       blindedBid: blindedBid,
       deposit: msg.value
   }));
   pendingReturns[msg.sender] += msg.value;   
    //State change
    state = States.ABB; 
}

function cancelABB () 
 
{
    require(state == States.ABB);
      
    //State change
    state = States.C; 
}

function cancelRB () 
 
{
    require(state == States.RB);
      
    //State change
    state = States.C; 
}

function close () 
 
{
    require(state == States.ABB);
   
    state = States.RB; 
}

function finish () 
 
{
    require(state == States.RB);
   
    state = States.F; 
}

function reveal (  uint[] values, bytes32[] secrets) 
 
{
    require(state == States.RB);
   
    state = States.InTransition;
    //Actions
    	   for (uint i = 0; i < (bids[msg.sender].length < values.length ? 
        bids[msg.sender].length : values.length); i++) {
            var bid = bids[msg.sender][i];
            var (value, secret) = (values[i], secrets[i]);
			if (bid.blindedBid == keccak256(value, secret) && 
              bid.deposit >= value && value > highestBid) {
                highestBid = value;
                highestBidder = msg.sender;
            }
  	}         
    //State change
    state = States.RB; 
}

function unbid () 
 
{
    require(state == States.C);
    
    //State change
    state = States.InTransition;
    //Actions
       uint amount = pendingReturns[msg.sender];
    if (amount > 0) {
      msg.sender.transfer(amount);
      pendingReturns[msg.sender] = 0;
    }
   
    //State change
    state = States.C; 
}

function withdraw () 
 
{
    require(state == States.F);
    
    //State change
    state = States.InTransition;
    //Actions
      uint amount = pendingReturns[msg.sender];
        if (amount > 0) {
           if (msg.sender!= highestBidder)
           msg.sender.transfer(amount);
        else
           msg.sender.transfer(amount - highestBid);
        pendingReturns[msg.sender] = 0;
}
   
    //State change
    state = States.F; 
}


}
contract Voting {
  uint private creationTime = now;
  
  

  //States definition
  enum States {
    InTransition,
    Setup, 
    Canceled, 
    Casting, 
    Closed  
  }
  States private state = States.Setup;
  //Insert variable definitions

  mapping(address => bool) private participants;
  uint private numParticipants; // total number of participants
  uint private numVoters; // number of participants who have voted
  string[] private options;
  mapping(uint => uint) votes; // vote for each option (index of option in array)
//Transitions 
function addOption (string option  ) 
 
{
    require(state == States.Setup);
    
    //State change
    state = States.InTransition;
    //Actions
         options.push(option);    
    //State change
    state = States.Setup; 
}

function addParticipant (  address participant) 
 
{
    require(state == States.Setup);
   
    state = States.InTransition;
    //Actions
      participants[participant] = true;
    numParticipants += 1;   
    //State change
    state = States.Setup; 
}

function cancel () 
 
{
    require(state == States.Casting);
   
    state = States.Canceled; 
}

function cast (uint option  ) 
 
{
    require(state == States.Casting);
   
    state = States.InTransition;
    //Actions
          votes[option] += 1;
    participants[msg.sender] = false;
    numVoters += 1;   
    //State change
    state = States.Casting; 
}

function close () 
 
{
    require(state == States.Casting);
   
    state = States.Closed; 
}

function open () 
 
{
    require(state == States.Setup);
   
    state = States.Casting; 
}

function removeOption (  uint option) 
 
{
    require(state == States.Setup);
   
    state = States.InTransition;
    //Actions
               options[option] = options[options.length - 1];
    options.length -= 1;   
    //State change
    state = States.Setup; 
}

function removeParticipant (  address participant) 
 
{
    require(state == States.Setup);
   
    state = States.InTransition;
    //Actions
      participants[participant] = false;
    numParticipants -= 1;   
    //State change
    state = States.Setup; 
}


}
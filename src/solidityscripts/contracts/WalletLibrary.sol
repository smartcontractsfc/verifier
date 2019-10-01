contract WalletLibrary {
  uint private creationTime = now;
  
  

  //States definition
  enum States {
    InTransition,
    InitialState
}
  States private state = States.InitialState;
  //Insert variable definitions

 
  address constant _walletLibrary = 0xcafecafecafecafecafecafecafecafecafecafe;

 
  uint public m_required;
 
  uint public m_numOwners;

  uint public m_dailyLimit;
  uint public m_spentToday;
  uint public m_lastDay;

 
  uint[256] m_owners;

  uint constant c_maxOwners = 250;
 
  mapping(uint => uint) m_ownerIndex;
 
  mapping(bytes32 => PendingState) m_pending;
  bytes32[] m_pendingIndex;

 
  mapping (bytes32 => Transaction) m_txs;
 

 
  struct PendingState {
    uint yetNeeded;
    uint ownersDone;
    uint index;
  }

 
  struct Transaction {
    address to;
    uint value;
    bytes data;
  }
  
 

 
 
  event Confirmation(address owner, bytes32 operation);
  event Revoke(address owner, bytes32 operation);

 
  event OwnerChanged(address oldOwner, address newOwner);
  event OwnerAdded(address newOwner);
  event OwnerRemoved(address oldOwner);

 
  event RequirementChanged(uint newRequirement); 

 
  event Deposit(address _from, uint value);
 
  event SingleTransact(address owner, uint value, address to, bytes data, address created);
 
  event MultiTransact(address owner, bytes32 operation, uint value, address to, bytes data, address created);
 
  event ConfirmationNeeded(bytes32 operation, address initiator, uint value, address to, bytes data);

 
  modifier onlyowner {
    if (isOwner(msg.sender))
      _;
  }
 
 
 
  modifier onlymanyowners(bytes32 _operation) {
    if (confirmAndCheck(_operation))
      _;
  }
  
 
  modifier only_uninitialized { if (m_numOwners > 0) throw; _; }

 

 
  
//Transitions 
function addOwner (address _owner) 
  onlymanyowners(sha3(msg.data)) external   
{
    require(state == States.InitialState);
   
    state = States.InTransition;
    //Actions
    if (isOwner(_owner)) return;

    clearPending();
    if (m_numOwners >= c_maxOwners)
      reorganizeOwners();
    if (m_numOwners >= c_maxOwners)
      return;
    m_numOwners++;
    m_owners[m_numOwners] = uint(_owner);
    m_ownerIndex[uint(_owner)] = m_numOwners;
    OwnerAdded(_owner);
     
    //State change
    state = States.InitialState; 
}

function changeOwner (address _from, address _to) 
  onlymanyowners(sha3(msg.data)) external   
{
    require(state == States.InitialState);
   
    state = States.InTransition;
    //Actions
    if (isOwner(_to)) return;
    uint ownerIndex = m_ownerIndex[uint(_from)];
    if (ownerIndex == 0) return;

    clearPending();
    m_owners[ownerIndex] = uint(_to);
    m_ownerIndex[uint(_from)] = 0;
    m_ownerIndex[uint(_to)] = ownerIndex;
    OwnerChanged(_from, _to);
     
    //State change
    state = States.InitialState; 
}

function changeRequirement (uint _newRequired) 
  onlymanyowners(sha3(msg.data)) external   
{
    require(state == States.InitialState);
   
    state = States.InTransition;
    //Actions
    if (_newRequired > m_numOwners) return;
    m_required = _newRequired;
    clearPending();
    RequirementChanged(_newRequired);
     
    //State change
    state = States.InitialState; 
}

function clearPending () 
  internal   
{
    require(state == States.InitialState);
    
    //State change
    state = States.InTransition;
    //Actions
    uint length = m_pendingIndex.length;

    for (uint i = 0; i < length; ++i) {
      delete m_txs[m_pendingIndex[i]];

      if (m_pendingIndex[i] != 0)
        delete m_pending[m_pendingIndex[i]];
    }

    delete m_pendingIndex;
     
    //State change
    state = States.InitialState; 
}

function confirm (bytes32 _h) 
  onlymanyowners(_h)    returns (bool o_success) 
{
    require(state == States.InitialState);
   
    state = States.InTransition;
    //Actions
    if (m_txs[_h].to != 0 || m_txs[_h].value != 0 || m_txs[_h].data.length != 0) {
      address created;
      if (m_txs[_h].to == 0) {
        created = create(m_txs[_h].value, m_txs[_h].data);
      } else {
        if (!m_txs[_h].to.call.value(m_txs[_h].value)(m_txs[_h].data))
          throw;
      }

      MultiTransact(msg.sender, _h, m_txs[_h].value, m_txs[_h].to, m_txs[_h].data, created);
      delete m_txs[_h];
      return true;
    }
     
    //State change
    state = States.InitialState; 
}

function confirmAndCheck (bytes32 _operation) 
  internal    returns (bool) 
{
    require(state == States.InitialState);
    
    //State change
    state = States.InTransition;
    //Actions
    uint ownerIndex = m_ownerIndex[uint(msg.sender)];
   
    if (ownerIndex == 0) return;

    var pending = m_pending[_operation];
   
    if (pending.yetNeeded == 0) {
     
      pending.yetNeeded = m_required;
     
      pending.ownersDone = 0;
      pending.index = m_pendingIndex.length++;
      m_pendingIndex[pending.index] = _operation;
    }
   
    uint ownerIndexBit = 2**ownerIndex;
   
    if (pending.ownersDone & ownerIndexBit == 0) {
      Confirmation(msg.sender, _operation);
     
      if (pending.yetNeeded <= 1) {
       
        delete m_pendingIndex[m_pending[_operation].index];
        delete m_pending[_operation];
        return true;
      }
      else
      {
       
        pending.yetNeeded--;
        pending.ownersDone |= ownerIndexBit;
      }
    }
     
    //State change
    state = States.InitialState; 
}

function create (uint _value, bytes _code) 
  internal    returns (address o_addr) 
{
    require(state == States.InitialState);
    
    //State change
    state = States.InTransition;
    //Actions
    assembly {
      o_addr := create(_value, add(_code, 0x20), mload(_code))
      jumpi('', iszero(extcodesize(o_addr)))
    }
     
    //State change
    state = States.InitialState; 
}

function execute (address _to, uint _value, bytes _data) 
  external onlyowner    returns (bytes32 o_hash) 
{
    require(state == States.InitialState);
   
    state = States.InTransition;
    //Actions
    if ((_data.length == 0 && underLimit(_value)) || m_required == 1) {
     
      address created;
      if (_to == 0) {
        created = create(_value, _data);
      } else {
        if (!_to.call.value(_value)(_data))
          throw;
      }
      SingleTransact(msg.sender, _value, _to, _data, created);
    } else {
     
      o_hash = sha3(msg.data, block.number);
     
      if (m_txs[o_hash].to == 0 && m_txs[o_hash].value == 0 && m_txs[o_hash].data.length == 0) {
        m_txs[o_hash].to = _to;
        m_txs[o_hash].value = _value;
        m_txs[o_hash].data = _data;
      }
      if (!confirm(o_hash)) {
        ConfirmationNeeded(o_hash, msg.sender, _value, _to, _data);
      }
    }
     
    //State change
    state = States.InitialState; 
}

function getOwner (uint ownerIndex) 
  external constant    returns (address) 
{
    require(state == States.InitialState);
    
    //State change
    state = States.InTransition;
    //Actions
    return address(m_owners[ownerIndex + 1]);
     
    //State change
    state = States.InitialState; 
}

function hasConfirmed (bytes32 _operation, address _owner) 
  external constant    returns (bool) 
{
    require(state == States.InitialState);
    
    //State change
    state = States.InTransition;
    //Actions
    var pending = m_pending[_operation];
    uint ownerIndex = m_ownerIndex[uint(_owner)];

   
    if (ownerIndex == 0) return false;

   
    uint ownerIndexBit = 2**ownerIndex;
    return !(pending.ownersDone & ownerIndexBit == 0);
     
    //State change
    state = States.InitialState; 
}

function initDaylimit (uint _limit) 
  only_uninitialized   
{
    require(state == States.InitialState);
   
    state = States.InTransition;
    //Actions
    m_dailyLimit = _limit;
    m_lastDay = today();
     
    //State change
    state = States.InitialState; 
}

function initMultiowned (address[] _owners, uint _required) 
  only_uninitialized   
{
    require(state == States.InitialState);
   
    state = States.InTransition;
    //Actions
    m_numOwners = _owners.length + 1;
    m_owners[1] = uint(msg.sender);
    m_ownerIndex[uint(msg.sender)] = 1;
    for (uint i = 0; i < _owners.length; ++i)
    {
      m_owners[2 + i] = uint(_owners[i]);
      m_ownerIndex[uint(_owners[i])] = 2 + i;
    }
    m_required = _required;
     
    //State change
    state = States.InitialState; 
}

function initWallet (address[] _owners, uint _required, uint _daylimit) 
  only_uninitialized   
{
    require(state == States.InitialState);
   
    state = States.InTransition;
    //Actions
    initDaylimit(_daylimit);
    initMultiowned(_owners, _required);
     
    //State change
    state = States.InitialState; 
}

function isOwner (address _addr) 
  constant    returns (bool) 
{
    require(state == States.InitialState);
    
    //State change
    state = States.InTransition;
    //Actions
    return m_ownerIndex[uint(_addr)] > 0;
     
    //State change
    state = States.InitialState; 
}

function kill (address _to) 
  onlymanyowners(sha3(msg.data)) external   
{
    require(state == States.InitialState);
   
    state = States.InTransition;
    //Actions
    suicide(_to);
     
    //State change
    state = States.InitialState; 
}

function removeOwner (address _owner) 
  onlymanyowners(sha3(msg.data)) external   
{
    require(state == States.InitialState);
   
    state = States.InTransition;
    //Actions
    uint ownerIndex = m_ownerIndex[uint(_owner)];
    if (ownerIndex == 0) return;
    if (m_required > m_numOwners - 1) return;

    m_owners[ownerIndex] = 0;
    m_ownerIndex[uint(_owner)] = 0;
    clearPending();
    reorganizeOwners();
    OwnerRemoved(_owner);
     
    //State change
    state = States.InitialState; 
}

function reorganizeOwners () 
  private   
{
    require(state == States.InitialState);
    
    //State change
    state = States.InTransition;
    //Actions
    uint free = 1;
    while (free < m_numOwners)
    {
      while (free < m_numOwners && m_owners[free] != 0) free++;
      while (m_numOwners > 1 && m_owners[m_numOwners] == 0) m_numOwners--;
      if (free < m_numOwners && m_owners[m_numOwners] != 0 && m_owners[free] == 0)
      {
        m_owners[free] = m_owners[m_numOwners];
        m_ownerIndex[m_owners[free]] = free;
        m_owners[m_numOwners] = 0;
      }
    }
     
    //State change
    state = States.InitialState; 
}

function resetSpentToday () 
  onlymanyowners(sha3(msg.data)) external   
{
    require(state == States.InitialState);
   
    state = States.InTransition;
    //Actions
    m_spentToday = 0;
     
    //State change
    state = States.InitialState; 
}

function revoke (bytes32 _operation) 
  external   
{
    require(state == States.InitialState);
    
    //State change
    state = States.InTransition;
    //Actions
    uint ownerIndex = m_ownerIndex[uint(msg.sender)];
   
    if (ownerIndex == 0) return;
    uint ownerIndexBit = 2**ownerIndex;
    var pending = m_pending[_operation];
    if (pending.ownersDone & ownerIndexBit > 0) {
      pending.yetNeeded++;
      pending.ownersDone -= ownerIndexBit;
      Revoke(msg.sender, _operation);
    }
     
    //State change
    state = States.InitialState; 
}

function setDailyLimit (uint _newLimit) 
  onlymanyowners(sha3(msg.data)) external   
{
    require(state == States.InitialState);
   
    state = States.InTransition;
    //Actions
    m_dailyLimit = _newLimit;
     
    //State change
    state = States.InitialState; 
}

function today () 
  private constant    returns (uint) 
{
    require(state == States.InitialState);
    
    //State change
    state = States.InTransition;
    //Actions
    return now / 1 days;    
    //State change
    state = States.InitialState; 
}

function underLimit (uint _value) 
  internal onlyowner    returns (bool) 
{
    require(state == States.InitialState);
   
    state = States.InTransition;
    //Actions
    if (today() > m_lastDay) {
      m_spentToday = 0;
      m_lastDay = today();
    }
   
   
    if (m_spentToday + _value >= m_spentToday && m_spentToday + _value <= m_dailyLimit) {
      m_spentToday += _value;
      return true;
    }
    return false;
     
    //State change
    state = States.InitialState; 
}


}
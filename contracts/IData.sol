pragma solidity ^0.5.0;
pragma experimental ABIEncoderV2;

import "./Enums.sol";

contract IData {
    
    address payable private Target;
    address payable private Mitigator;
    
    uint private DeadlineInterval;
    uint256 private Deadline;
    uint256 private StartTime = now;
    
    string private ListOfAddresses;
    string private Proof ="";
    uint private AmountOfAddresses;
    
    Enums.Rating private TargetRating;
    Enums.Rating private MitigatorRating;
    event Received(uint256 value);

    constructor (address payable T,address payable M, uint256 Interval,string memory listOfAddresses,uint amount) 
    public
    payable
    {
        Target = T;
        Mitigator = M;
        DeadlineInterval = Interval;
        ListOfAddresses = listOfAddresses;
        AmountOfAddresses = amount;
    }
    
	function() payable external {
		emit Received(msg.value);
	}
	
	function transferFunds(address payable receiver) public {   
        receiver.transfer(address(this).balance);
    }

    function getMitigator() public view returns (address payable){return Mitigator;}
    function getTarget() public view returns (address payable){ return Target;}
    
    function getProof() public view returns (string memory){return Proof;}
    function setProof(string memory _Proof) public {Proof = _Proof;}

    function getTargetRating()  public view returns (Enums.Rating){return TargetRating;}
    function getMitigatorRating()  public view returns (Enums.Rating){return MitigatorRating;}
    
    function setTargetRating(Enums.Rating _Rating) public {TargetRating = _Rating;}
    function setMitigatorRating(Enums.Rating _Rating)  public {MitigatorRating = _Rating;}

    function getStartTime() public view returns (uint256){return StartTime;}
    
    function setDeadline()public {Deadline = now + DeadlineInterval * 1 seconds;}
    function getDeadline() public view returns (uint256){return Deadline;}
    

}
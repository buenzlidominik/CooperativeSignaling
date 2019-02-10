pragma solidity ^0.5.0;

import "./Enums.sol";
import "./IActor.sol";

contract IData {
    
    address payable private Target;
    address payable private Mitigator;
    
    uint256 private DeadlineInterval;
    uint256 private StartTime = now;
    uint256 private EndTime;
	
    string private ListOfAddresses;
    string private Proof ="";
    uint256 private OfferedFunds;
	
    Enums.Rating private TargetRating;
    Enums.Rating private MitigatorRating;
    event ReceivedData(uint256 value);

    constructor (address payable _Target,address payable _Mitigator, uint256 _Interval,string memory _ListOfAddresses,uint256 _OfferedFunds) 
    public
    payable
    {
        Target = _Target;
        Mitigator = _Mitigator;
        DeadlineInterval = _Interval;
        ListOfAddresses = _ListOfAddresses;
        OfferedFunds = _OfferedFunds;
    }
    
	function() payable external {
		emit ReceivedData(msg.value);
	}
	
	function transferFunds(address payable receiver) public {   
        IActor(receiver).getOwner().transfer(address(this).balance);
    }
	
	function getOfferedFunds() public view returns (uint256){return OfferedFunds;}
	
    function getMitigator() public view returns (address payable){return Mitigator;}
    function getTarget() public view returns (address payable){ return Target;}
    
    function getProof() public view returns (string memory){return Proof;}
	function isProofProvided() public view returns (bool){
		if(bytes(Proof).length>0){
			return true;
		}
		return false;
	}
    function setProof(string memory _Proof) public {Proof = _Proof;}

    function getTargetRating()  public view returns (Enums.Rating){return TargetRating;}
    function getMitigatorRating()  public view returns (Enums.Rating){return MitigatorRating;}
    
    function setTargetRating(Enums.Rating _Rating) public {TargetRating = _Rating;}
    function setMitigatorRating(Enums.Rating _Rating)  public {MitigatorRating = _Rating;}

    function getStartTime() public view returns (uint256){return StartTime;}
	function getEndTime() public view returns (uint256){return EndTime;}
    function getDeadlineInterval() public view returns (uint256){return DeadlineInterval;}
    

}
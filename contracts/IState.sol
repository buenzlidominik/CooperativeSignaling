pragma solidity ^0.5.0;

import "./IData.sol";

contract IState {

    address payable data;
    bool internal aborted;
    
	string public Statename = "IState";
	
    constructor(address payable _data) public payable {
		data = _data;
	}
        
    function canAdvance() public returns(bool){
        require(aborted!= true,"Process aborted");
        //require(getActorOfState().getOwner() == msg.sender,"not allowed");
        require(now>IData(data).getDeadline(),"Deadline exceeded");
        return true;
    }
    
    function execute() public {revert("Not Implemented");}
    function execute(bool value) public {revert("Not Implemented");}
    function execute(uint256 value) public {revert("Not Implemented");}
    function execute(string memory value) public {revert("Not Implemented");}
    
    function getActorOfState() public view returns(address);
    
    function abort() internal {aborted = true;}

	function getName() public view returns (string memory){return Statename;}
    
}
pragma solidity ^0.5.0;

import "./IState.sol";

contract StateStart is IState{
    
	address payable data;
	address payable owner;
	bool internal executable = true;
	bool internal aborted = false;
	
    constructor(address payable _data) public payable {
		data = _data;
		owner = IActor(IData(data).getTarget()).getOwner();
	}	
	
	function execute() external returns(Enums.StateType){
        require(executable,"Process not executable");
		if(aborted){
			executable=false;
			return Enums.StateType.ABORT; 
		}

		require(owner == tx.origin,"Error owner != tx.origin");
		
		executable=false;
		return Enums.StateType.APPROVE;
    }
	
	function execute(bool /*value*/) external returns(Enums.StateType) {revert("Not implemented");}
    function execute(uint256 /*value*/) external returns(Enums.StateType) {revert("Not implemented");}
    function execute(string calldata /*value*/) external returns(Enums.StateType) {revert("Not implemented");}     

	function abort() public returns(Enums.StateType){
		require(owner == tx.origin,"Error owner != tx.origin"); 
		aborted=true; 
		return Enums.StateType.ABORT; 
	}
	
	function getOwnerOfState() external view returns(address payable){return owner;}  
	
	function getStateType() external view returns(Enums.StateType){return Enums.StateType.REQUEST;}
    
}
pragma solidity ^0.5.0;

import "./IState.sol";

contract StateAbort is IState{
    
	address payable data;
	bool internal executable = false;
	
    constructor(address payable _data) public payable {
		data = _data;
		IData(data).setEndTime();
	}	
	
	function execute() external returns(Enums.StateType){revert("Not implemented");}
	function execute(bool /*value*/) external returns(Enums.StateType) {revert("Not implemented");}
    function execute(uint256 /*value*/) external returns(Enums.StateType) {revert("Not implemented");}
    function execute(string calldata /*value*/) external returns(Enums.StateType) {revert("Not implemented");}     
	
	function getOwnerOfState() external view returns(address payable){revert("No Owner");}  
	
	function getStateType() external view returns(Enums.StateType){return Enums.StateType.ABORT;}
	
}
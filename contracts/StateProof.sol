pragma solidity ^0.5.0;

import "./IState.sol";

contract StateProof is IState{

	address payable data;
	address payable owner;
	bool internal executable = true;
	bool internal aborted = false;
	uint256 internal deadline;
	
    constructor(address payable _data) public payable {
		data = _data;
		owner = IActor(IData(data).getMitigator()).getOwner();
		deadline = now + IData(data).getDeadlineInterval() * 1 seconds;
	}	
	
	function execute(bool /*value*/) external returns(Enums.StateType) {revert("Not implemented");}
    function execute(uint256 /*value*/) external returns(Enums.StateType) {revert("Not implemented");}
    function execute() external returns(Enums.StateType) {revert("Not implemented");}
	
    function execute(string calldata value) external returns(Enums.StateType){
        require(executable,"Process not executable");
		if(aborted){
			executable=false;
			return Enums.StateType.ABORT; 
		}
		if(!canBeSkipped()){
			require(owner == tx.origin,"Error owner != tx.origin");
		}else{
			executable=false;
			return Enums.StateType.RATE_T;
		}
        IData(data).setProof(value);
		executable=false;
		return Enums.StateType.RATE_T;
    }

	function canBeSkipped() private view returns(bool){
		if(deadline<now){return false;}
		return true;
	}
	
	function abort() public returns(Enums.StateType){
		require(owner == tx.origin,"Error owner != tx.origin"); 
		aborted=true; 
		return Enums.StateType.ABORT; 
	}
	

   function getOwnerOfState() external view returns(address payable){return owner;}

}
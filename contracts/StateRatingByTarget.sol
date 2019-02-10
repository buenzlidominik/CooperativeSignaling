pragma solidity ^0.5.0;

import "./IState.sol";

contract StateRatingByTarget is IState{

	address payable data;
	address payable owner;
	bool internal executable = true;
	bool internal aborted = false;
	uint256 internal deadline;
	
    constructor(address payable _data) public payable {
		data = _data;
		owner = IActor(IData(data).getTarget()).getOwner();
		deadline = now + IData(data).getDeadlineInterval() * 1 seconds;
	}		
	
	function execute(uint256 value) external returns(Enums.StateType){
        require(executable,"Process not executable");
		if(canBeSkipped()){
			IData(data).setTargetRating(Enums.Rating.NA);
			executable=false;
			return checkForProof(IData(data).isProofProvided());
		}else{
			require(owner == tx.origin,"Error owner != tx.origin");			
		}
		IData(data).setTargetRating(Enums.Rating(value));
		executable=false;
		return checkForProof(IData(data).isProofProvided());
        
    }	
	function execute(bool /*value*/) external returns(Enums.StateType) {revert("Not implemented");}
    function execute() external returns(Enums.StateType) {revert("Not implemented");}
    function execute(string calldata /*value*/) external returns(Enums.StateType) {revert("Not implemented");}
       
	function checkForProof(bool isProvided) private pure returns (Enums.StateType){
		if(!isProvided){
			return Enums.StateType.EVALUATION;
		}else{
			return Enums.StateType.RATE_M;
		}
	} 
		
	function canBeSkipped() private view returns(bool){
		if(now>deadline){return true;}
		return false;
	}
	
	function abort() public returns(Enums.StateType){
		require(owner == tx.origin,"Error owner != tx.origin"); 
		aborted=true; 
		executable = false;
		IData(data).setTargetRating(Enums.Rating.NA);
		return Enums.StateType.RATE_M; 
	}
		
	function getOwnerOfState() external view returns(address payable){return owner;}

function getStateType() external view returns(Enums.StateType){return Enums.StateType.RATE_T;}	
}
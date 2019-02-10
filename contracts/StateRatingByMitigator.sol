pragma solidity ^0.5.0;

import "./IState.sol";

contract StateRatingByMitigator is IState{
	
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
	
    function execute(uint256 value) external returns(Enums.StateType){
        require(executable,"Process not executable");
		if(canBeSkipped()){
			IData(data).setMitigatorRating(Enums.Rating.NA);
			executable=false;
			return Enums.StateType.EVALUATION;
		}else{
			require(owner == tx.origin,"Error owner != tx.origin");
		}
        IData(data).setMitigatorRating(Enums.Rating(value));
		executable=false;
		return Enums.StateType.EVALUATION;
    }

	function execute(bool /*value*/) external returns(Enums.StateType) {revert("Not implemented");}
    function execute() external returns(Enums.StateType) {revert("Not implemented");}
    function execute(string calldata /*value*/) external returns(Enums.StateType) {revert("Not implemented");}
   
	function canBeSkipped() private view returns(bool){
		if(now>deadline){return true;}
		return false;
	}
	
	function abort() public returns(Enums.StateType){
		require(owner == tx.origin,"Error owner != tx.origin"); 
		aborted=true; 
		executable=false;
		IData(data).setMitigatorRating(Enums.Rating.NA);
		return Enums.StateType.EVALUATION; 
	}
	
	function getOwnerOfState() external view returns(address payable){return owner;}    
	
	function getStateType() external view returns(Enums.StateType){return Enums.StateType.RATE_M;}
}
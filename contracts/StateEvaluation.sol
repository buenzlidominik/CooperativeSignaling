pragma solidity ^0.5.0;

import "./IState.sol";
import "./IEvaluation.sol";
import "./EvaluationFactory.sol";

contract StateEvaluation is IState{
		
	address payable data;
	address payable owner;
	bool internal executable = true;
	bool internal aborted = false;
	uint256 internal deadline;
	
    constructor(address payable _data) public payable {
		data = _data;
		owner = msg.sender;
		deadline = now + IData(data).getDeadlineInterval() * 1 seconds;
	}	
	
    function execute() external returns(Enums.StateType){
        require(executable,"Process not executable");
		require(owner == msg.sender,"Error owner != msg.sender");

		address payable actor;
		Enums.StateType stateToSet;
		IEvaluation _Evaluation;
		if(IData(data).isProofProvided()){
			_Evaluation = EvaluationFactory.create(Enums.EvaluationType.WITHPROOF,IData(data).getTarget(),IData(data).getMitigator());
		}else{
			_Evaluation = EvaluationFactory.create(Enums.EvaluationType.WITHOUTPROOF,IData(data).getTarget(),IData(data).getMitigator());
		}
		
        (actor,stateToSet) = _Evaluation.evaluate(IData(data).getTargetRating(),IData(data).getMitigatorRating());
	
		if(actor!=address(0)){
			IData(data).transferFunds(actor);
		}
		executable=false;
		return stateToSet;
        
    }
	function execute(bool /*value*/) external returns(Enums.StateType) {revert("Not implemented");}
    function execute(uint256 /*value*/) external returns(Enums.StateType) {revert("Not implemented");}
    function execute(string calldata /*value*/) external returns(Enums.StateType) {revert("Not implemented");}
    
	function getOwnerOfState() external view returns(address payable){return owner;}  
	
	function getStateType() external view returns(Enums.StateType){return Enums.StateType.EVALUATION;}
}
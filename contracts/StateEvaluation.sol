pragma solidity ^0.5.0;

import "./IState.sol";
import "./IEvaluation.sol";
import "./EvaluationWithoutProof.sol";
import "./EvaluationWithProof.sol";

contract StateEvaluation is IState{
	
	constructor(address payable _data) IState(_data) public payable {}
	
    function execute() public{
        if(!canAdvance()){
            revert("Can't advance");
        }
		
		address payable actor;
		Enums.State stateToSet;
		IEvaluation _Evaluation;
		if(IData(data).isProofProvided()){
			_Evaluation = new EvaluationWithProof(IData(data).getTarget(),IData(data).getMitigator());
		}else{
			_Evaluation = new EvaluationWithoutProof(IData(data).getTarget(),IData(data).getMitigator());
		}
		
        (actor,stateToSet) = _Evaluation.evaluate(IData(data).getTargetRating(),IData(data).getMitigatorRating());
	
		if(actor!=address(0)){
			IData(data).transferFunds(actor);
		}
        abort();
    }
	
    function getActorOfState() public view returns(address){return IData(data).getTarget();}

}
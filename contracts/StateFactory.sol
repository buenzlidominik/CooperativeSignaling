pragma solidity ^0.5.0;

import "./Enums.sol";
import "./IState.sol";
import "./StateStart.sol";
import "./StateFunding.sol";
import "./StateRatingByMitigator.sol";
import "./StateEvaluation.sol";
import "./StateApprove.sol";
import "./StateProof.sol";
import "./StateRatingByTarget.sol";

library StateFactory{
    
    function create(Enums.StateType _Type,address payable data) 
    public
	returns (IState){
        
		if(_Type == Enums.StateType.REQUEST){
			return new StateStart(data);
		}else if(_Type == Enums.StateType.APPROVE){
			return new StateApprove(data);
		}else if(_Type == Enums.StateType.FUNDING){
			return new StateFunding(data);
		}else if(_Type == Enums.StateType.PROOF){
			return new StateProof(data);
		}else if(_Type == Enums.StateType.RATE_T){
			return new StateRatingByTarget(data);
		}else if(_Type == Enums.StateType.RATE_M){
			return new StateRatingByMitigator(data);
		}else if(_Type == Enums.StateType.EVALUATION){
			return new StateEvaluation(data);
		}else{
			revert("Type not in StateFactory");
		}
	}
    
}
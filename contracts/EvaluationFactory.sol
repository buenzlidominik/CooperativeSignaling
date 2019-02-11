pragma solidity ^0.5.0;

import "./Enums.sol";
import "./IEvaluation.sol";
import "./EvaluationWithProof.sol";
import "./EvaluationWithoutProof.sol";


library EvaluationFactory{
    
    function create(Enums.EvaluationType _Type,address _TargetAddress,address _MitigatorAddress) 
    public
	returns (IEvaluation){
        
		if(_Type == Enums.EvaluationType.WITHPROOF){
			return new EvaluationWithProof(_TargetAddress,_MitigatorAddress);
		}else if(_Type == Enums.EvaluationType.WITHOUTPROOF){
			return new EvaluationWithoutProof(_TargetAddress,_MitigatorAddress);
		}else{
			revert("Type not in EvaluationFactory");
		}
	}
    
}
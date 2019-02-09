pragma solidity ^0.5.0;

import "./Enums.sol";
import "./IEvaluation.sol";

contract  EvaluationWithProof is IEvaluation{
	
	constructor(address _TargetAddress,address _MitigatorAddress) public IEvaluation(_TargetAddress,_MitigatorAddress) {}

    function evaluate(Enums.Rating TargetRating, Enums.Rating MitigatorRating) public view returns (address,Enums.State){    
        if(TargetRating==Enums.Rating.POS){
            return acknowledged(MitigatorRating);
        }else if(TargetRating==Enums.Rating.NEG){
            return rejected(MitigatorRating);
        }else{
            return selfish(MitigatorRating);
        }
    }

    function acknowledged(Enums.Rating MitigatorRating) public view returns (address,Enums.State){    
        if(MitigatorRating==Enums.Rating.POS){
			return(MitigatorAddress,Enums.State.COMPLETE);
        }else{
            return(address(0),Enums.State.ABORT);
        }
    }
    
    function selfish(Enums.Rating MitigatorRating) public view returns (address,Enums.State){    
        if(MitigatorRating==Enums.Rating.NEG){
            return(MitigatorAddress,Enums.State.COMPLETE);
        }else{
            return(address(0),Enums.State.ABORT);
        }
    }
    
    function rejected(Enums.Rating MitigatorRating) public view returns (address,Enums.State){    
        if(MitigatorRating==Enums.Rating.NEG){
            return(address(0),Enums.State.ESCALATE);
        }else{
            return(TargetAddress,Enums.State.COMPLETE);
        }
    }
}
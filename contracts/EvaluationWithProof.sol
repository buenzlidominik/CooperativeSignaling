pragma solidity ^0.5.0;

import "./Enums.sol";
import "./IEvaluation.sol";

contract  EvaluationWithProof is IEvaluation{
	
	constructor(address payable _TargetAddress,address payable _MitigatorAddress) public IEvaluation(_TargetAddress,_MitigatorAddress) {}

    function evaluate(Enums.Rating TargetRating, Enums.Rating MitigatorRating) public view returns (address payable,Enums.State){    
        if(TargetRating==Enums.Rating.ACK){
            return acknowledged(MitigatorRating);
        }else if(TargetRating==Enums.Rating.REJ){
            return rejected(MitigatorRating);
        }else{
            return selfish(MitigatorRating);
        }
    }

    function acknowledged(Enums.Rating MitigatorRating) public view returns (address payable,Enums.State){    
        if(MitigatorRating==Enums.Rating.ACK){
			return(MitigatorAddress,Enums.State.COMPLETE);
        }else{
            return(address(0),Enums.State.ABORT);
        }
    }
    
    function selfish(Enums.Rating MitigatorRating) public view returns (address payable,Enums.State){    
        if(MitigatorRating==Enums.Rating.REJ){
            return(MitigatorAddress,Enums.State.COMPLETE);
        }else{
            return(address(0),Enums.State.ABORT);
        }
    }
    
    function rejected(Enums.Rating MitigatorRating) public view returns (address payable,Enums.State){    
        if(MitigatorRating==Enums.Rating.REJ){
            return(address(0),Enums.State.ESCALATE);
        }else{
            return(TargetAddress,Enums.State.COMPLETE);
        }
    }
}
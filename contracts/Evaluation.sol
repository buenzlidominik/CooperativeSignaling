pragma solidity ^0.5.0;

import "./Enums.sol";

contract  Evaluation {

	address private OwningContract;
	address private TargetAddress;
	address private MitigatorAddress;
	
	constructor(address owner,address _TargetAddress,address _MitigatorAddress) public{
		OwningContract = owner;
		TargetAddress= _TargetAddress;
		MitigatorAddress= _MitigatorAddress;
	}

    function evaluate(bool _ProofWasProvided, Enums.Rating TargetRating, Enums.Rating MitigatorRating) public view returns (address,Enums.State){    
        if(_ProofWasProvided){
            return evaluationWithProof(TargetRating,MitigatorRating);
        }else{
            return evaluationWithoutProof(TargetRating);
        }
    }
    
    function evaluationWithoutProof(Enums.Rating TargetRating) public view returns (address,Enums.State){    
        if(TargetRating==Enums.Rating.REJ){
				return(TargetAddress,Enums.State.COMPLETE);
            }else{
                return(address(0),Enums.State.ABORT);
            }
    }
    
    function evaluationWithProof(Enums.Rating TargetRating, Enums.Rating MitigatorRating) public view returns (address,Enums.State){    
        if(TargetRating==Enums.Rating.ACK){
            return evaluationWithProofAcknowledged(MitigatorRating);
        }else if(TargetRating==Enums.Rating.REJ){
            return evaluationWithProofRejected(MitigatorRating);
        }else{
            return evaluationWithProofSelfish(MitigatorRating);
        }
    }
    
    function evaluationWithProofAcknowledged(Enums.Rating MitigatorRating) public view returns (address,Enums.State){    
        if(MitigatorRating==Enums.Rating.ACK){
			return(MitigatorAddress,Enums.State.COMPLETE);
        }else{
            return(address(0),Enums.State.ABORT);
        }
    }
    
    function evaluationWithProofSelfish(Enums.Rating MitigatorRating) public view returns (address,Enums.State){    
        if(MitigatorRating==Enums.Rating.ACK){
            return(MitigatorAddress,Enums.State.COMPLETE);
        }else{
            return(address(0),Enums.State.ABORT);
        }
    }
    
    function evaluationWithProofRejected(Enums.Rating MitigatorRating) public view returns (address,Enums.State){    
        if(MitigatorRating==Enums.Rating.ACK){
            return(address(0),Enums.State.ESCALATE);
        }else{
            return(TargetAddress,Enums.State.COMPLETE);
        }
    }
}
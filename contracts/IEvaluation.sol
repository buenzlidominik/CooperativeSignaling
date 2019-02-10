pragma solidity ^0.5.0;

import "./Enums.sol";

interface  IEvaluation {

    function evaluate(Enums.Rating TargetRating, Enums.Rating MitigatorRating) external view returns (address payable,Enums.StateType);
}
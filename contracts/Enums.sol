pragma solidity ^0.5.0;

contract  Enums {

    enum Rating {NEG,NA,POS}
	enum EvaluationType {WITHPROOF,WITHOUTPROOF}
	enum StateType {REQUEST,APPROVE,FUNDING,PROOF,RATE_T,RATE_M,EVALUATION,COMPLETE,ABORT,ESCALATE}
}
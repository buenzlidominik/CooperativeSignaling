pragma solidity ^0.5.0;

contract  Enums {

	enum State {REQUEST,APPROVE,FUNDING,PROOF,TRATE,MRATE,COMPLETE,ABORT,ESCALATE}
    enum Rating {NEG,NA,POS}
	enum EvaluationType{WITHPROOF,WITHOUTPROOF}
}
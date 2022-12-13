//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract Stat  {
    uint public txNum;
    uint64 public startTime;
    
	function reset(uint64 _startTime) public {
		startTime = _startTime;
		txNum = 0;
	}

    function add() public {
        txNum += 1;
    }
}

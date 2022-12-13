//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

// // Represent a 18 decimal, 256 bit wide fixed point type using a user defined value type.
// type UFixed256x18 is uint256;

struct Funder {
    address addr;
    uint amount;
    string desc;
    bool isDeleted;
    uint64 createTime;
    bytes photo;
    bool[3] flags;
    // Funder[] friends;
    // mapping (address => uint) balances;
}

contract InputTypes  {
    uint public txNum;
    uint64 public startTime;
    string public desc;
    mapping (uint => Funder) public funders;
    uint public numFunders;
    
	function reset(uint64 _startTime) public {
		startTime = _startTime;
		txNum = 0;
	}

    function add() public {
        txNum += 1;
    }

    function setDesc(string memory _desc) public {
        desc = _desc;
        txNum += 1;
    }

    function addFunder(Funder memory f) public {
        funders[numFunders++] = f;
        txNum += 1;
    }

    function addFunders(Funder[] memory fs) public {
        for(uint i =0; i < fs.length; i++){
            funders[numFunders++] = fs[i];
        }
        
        txNum += 1;
    }

    // function addFixed(UFixed256x18 a, UFixed256x18 b) internal pure returns (UFixed256x18) {
    //     return UFixed256x18.wrap(UFixed256x18.unwrap(a) + UFixed256x18.unwrap(b));
    // }

}


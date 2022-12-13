// contracts/GLDToken.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract MyERC20 is ERC20 {
    event TestFail(int256 indexed num, uint256 indexed result);
    mapping(uint256 => string) private stringList;

    constructor(uint256 initialSupply) ERC20("MT", "MT") {
        _mint(msg.sender, initialSupply);
    }

    function mint(address to, uint256 amount) public {
        _mint(to, amount);
    }

    function decimals() public view virtual override returns (uint8) {
        return 8;
    }

    function setStringList(uint256 n) public {
        for (uint256 i = 0; i < n; i++) {
            stringList[i] = string(
                abi.encodePacked("test_item", Strings.toString(i))
            );
        }
    }

    function testFail(int256 num) public {
        require(num > -2, "num is less than -1");
        // endless loop
        while (num == -1) {
            _mint(msg.sender, 1);
        }
        uint256 result = 0;
        for (uint256 i = 0; i < uint256(num); i++) {
            result += i;
        }
        emit TestFail(num, result);
    }
}

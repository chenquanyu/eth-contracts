// contracts/GameItem.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract MyERC721 is ERC721  ("KC721", "KC721") {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    // constructor() ERC721("KC721", "KC721") {}

    function awardItem(address player)
        public
        returns (uint256)
    {
        _tokenIds.increment();

        uint256 newItemId = _tokenIds.current();
        _mint(player, newItemId);
        //  _setTokenURI(newItemId, tokenURI);

        return newItemId;
    }

}
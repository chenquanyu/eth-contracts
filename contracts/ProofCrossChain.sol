//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract ProofCrossChain {

    struct Content {
        string value;
        bool isCrossChain; 
    }

    string public proofName;

    mapping (string => Content) public proofs;

    event Set(string _key, string _value, bool _isCrossChain);
    event Remove(string _key, bool _isCrossChain);

    constructor(string memory _proofName) {
        proofName = _proofName;
    }

    function set(string memory _key, string memory _value) public {
        setCrossChain(_key, _value, false);
    }

    function setCrossChain(string memory _key, string memory _value, bool _isCrossChain) public {
        proofs[_key] = Content({
            value: _value,
            isCrossChain: _isCrossChain
            });
        emit Set(_key, _value, _isCrossChain);
    }

    function remove(string memory _key) public {
        removeCrossChain(_key, false);
    }

    function removeCrossChain(string memory _key, bool _isCrossChain) public {
        delete proofs[_key];
        emit Remove(_key, _isCrossChain);
    }

    function get(string memory _key) public view returns(string memory){
        return proofs[_key].value;
    }
}
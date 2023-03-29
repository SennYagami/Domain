pragma solidity ^0.8.17;

import "../registry/DID.sol";

contract DefaultReverseResolver {
    // namehash('addr.reverse')
    bytes32 constant ADDR_REVERSE_NODE = 0x91d1777781884d03a6757a803996e38de2a42967fb37eeaca72729271025a9e2;

    DID public did;
    mapping (bytes32 => string) public name;

  
    modifier onlyOwner(bytes32 node) {
        require(msg.sender == did.owner(node));
        _;
    }

    
    constructor(DID didAddr) {
        did = didAddr;
    }

   
    function setName(bytes32 node, string memory _name) public onlyOwner(node) {
        name[node] = _name;
    }
}

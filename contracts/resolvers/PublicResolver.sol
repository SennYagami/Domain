pragma solidity ^0.8.17;
pragma experimental ABIEncoderV2;

import "../registry/DID.sol";
import "./profiles/ABIResolver.sol";
import "./profiles/AddrResolver.sol";
import "./profiles/ContentHashResolver.sol";
import "./profiles/DNSResolver.sol";
import "./profiles/InterfaceResolver.sol";
import "./profiles/NameResolver.sol";
import "./profiles/PubkeyResolver.sol";
import "./profiles/TextResolver.sol";
import "./profiles/CommissonResolver.sol";


contract PublicResolver is ABIResolver, AddrResolver, ContentHashResolver, DNSResolver, InterfaceResolver, NameResolver, PubkeyResolver, TextResolver, CommissonResolver {
    DID did;

    mapping(bytes32=>mapping(address=>mapping(address=>bool))) public authorisations;

    event AuthorisationChanged(bytes32 indexed node, address indexed owner, address indexed target, bool isAuthorised);

    constructor(DID _did) {
        did = _did;
    }

    function setAuthorisation(bytes32 node, address target, bool isAuthorised) external {
        authorisations[node][msg.sender][target] = isAuthorised;
        emit AuthorisationChanged(node, msg.sender, target, isAuthorised);
    }

    function isAuthorised(bytes32 node) internal override view returns(bool) {
        address owner = did.getOwner(node);
        return owner == msg.sender || authorisations[node][owner][msg.sender];
    }

    function multicall(bytes[] calldata data) external returns(bytes[] memory results) {
        results = new bytes[](data.length);
        for(uint i = 0; i < data.length; i++) {
            (bool success, bytes memory result) = address(this).delegatecall(data[i]);
            require(success);
            results[i] = result;
        }
        return results;
    }

    function supportsInterface(bytes4 interfaceID) virtual override(ABIResolver, AddrResolver, ContentHashResolver, DNSResolver, InterfaceResolver, NameResolver, PubkeyResolver, TextResolver, CommissonResolver) public pure returns(bool) {
        return super.supportsInterface(interfaceID);
    }
}

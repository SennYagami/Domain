pragma solidity ^0.8.17;
import "../ResolverBase.sol";

abstract contract CommissonResolver is ResolverBase {
    bytes4 constant private CAA_INTERFACE_ID = 0x114711eb;

    event CommissionAcceptAddrChanged(bytes32 indexed node, address caa);

    mapping(bytes32=>address) _commissionAcceptAddress;


    /**
     * Returns the commission accept address .
     * @param nodehash  the node hash
     * @return The commission address.
     */
    function commissionAcceptAddress(bytes32 nodehash) public view returns (address) {
       return _commissionAcceptAddress[nodehash];
    }


    function setCommissionAcceptAddress(bytes32 nodehash, address caa) external authorised(nodehash) {
        emit CommissionAcceptAddrChanged(nodehash,caa);
        _commissionAcceptAddress[nodehash] = caa;
    }

    function supportsInterface(bytes4 interfaceID) virtual override public pure returns(bool) {
        return interfaceID == CAA_INTERFACE_ID  || super.supportsInterface(interfaceID);
    }
}

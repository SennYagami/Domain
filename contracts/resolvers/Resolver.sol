pragma solidity >=0.4.25;
pragma experimental ABIEncoderV2;

/**
 * A generic resolver interface which includes all the functions 
 */
interface Resolver{
    event AddrChanged(bytes32 indexed node, address a);
    event AddressChanged(bytes32 indexed node, uint coinType, bytes newAddress);
    event NameChanged(bytes32 indexed node, string name);
    event ABIChanged(bytes32 indexed node, uint256 indexed contentType);
    event PubkeyChanged(bytes32 indexed node, bytes32 x, bytes32 y);
    event TextChanged(bytes32 indexed node, string indexed indexedKey, string key);
    event ContenthashChanged(bytes32 indexed node, bytes hash);


    function ABI(bytes32 node, uint256 contentTypes) external view returns (uint256, bytes memory);
    function addr(bytes32 node) external view returns (address);
    function addr(bytes32 node, uint coinType) external view returns(bytes memory);
    function contenthash(bytes32 node) external view returns (bytes memory);
    function dnsrr(bytes32 node) external view returns (bytes memory);
    function name(bytes32 node) external view returns (string memory);
    function pubkey(bytes32 node) external view returns (bytes32 x, bytes32 y);
    function text(bytes32 node, string calldata key) external view returns (string memory);
    function interfaceImplementer(bytes32 node, bytes4 interfaceID) external view returns (address);
    function setABI(bytes32 node, uint256 contentType, bytes calldata data) external;
    function setAddr(bytes32 node, address addr) external;
    function setAddr(bytes32 node, uint coinType, bytes calldata a) external;
    function setContenthash(bytes32 node, bytes calldata hash) external;
    function setDnsrr(bytes32 node, bytes calldata data) external;
    function setName(bytes32 node, string calldata _name) external;
    function setPubkey(bytes32 node, bytes32 x, bytes32 y) external;
    function setText(bytes32 node, string calldata key, string calldata value) external;
    function setInterface(bytes32 node, bytes4 interfaceID, address implementer) external;
    function supportsInterface(bytes4 interfaceID) external pure returns (bool);
    function multicall(bytes[] calldata data) external returns(bytes[] memory results);
    function commissionAcceptAddress(bytes32 nodehash) external view returns (address);
    function setCommissionAcceptAddress(bytes32 nodehash, address caa) external ;

}

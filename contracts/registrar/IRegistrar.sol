// SPDX-License-Identifier: NO LICENSE
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import "./IPriceOracle.sol";

struct Domain {
    string rootDomainName;
    string secondaryDomainName;
}

interface IRegistrar is IERC721{

    event NameRegistered(string rootDomainName, string secondaryDomainName,
        address indexed owner, uint256 cost, uint256 expires);

    event NameRenewed(string rootDomainName, string secondaryDomainName, uint256 cost,
        uint256 expires);

    event ControllerAdded(address indexed controller);
    event ControllerRemoved(address indexed controller);


    // Authorises a controller, who can register and renew domains.
    function addController(address controller) external;

    // Revoke controller permission for an address.
    function removeController(address controller) external;

    // Returns the expiration timestamp of the specified label hash.
    function nameExpires(string memory domain) external view returns (uint256);

    // Set the resolver for the TLD this registrar manages.
    function setResolver(string memory domain, address resolver) external;

    function register(string memory rootDomainName, string memory secondaryDomainName, address owner,
        uint256 duration, bytes32 secret, address resolver, bytes[] calldata data,
        bool reverseRecord, uint16 ownerControlledFuses) external payable;

    function renew(string memory rootDomainName, string memory secondaryDomainName, uint256 duration) external payable;

    function rentPrice(
        string memory domain,
        uint256 duration
    ) external view returns (IPriceOracle.Price memory);

    function available(string memory) external returns (bool);

    function makeCommitment(
        string memory,
        address,
        uint256,
        bytes32,
        address,
        bytes[] calldata,
        bool,
        uint16
    ) external pure returns (bytes32);

    function commit(bytes32) external;

}

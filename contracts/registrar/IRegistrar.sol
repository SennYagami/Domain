// SPDX-License-Identifier: NO LICENSE
pragma solidity ^0.8.17;

import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";

struct Domain {
    string rootDomainName;
    string secondaryDomainName;
}

interface IRegistrar is IERC721Upgradeable{

    event NameRegistered(string rootDomainName, string secondaryDomainName,
        address indexed owner, uint256 expires);

    event NameRenewed(uint256 tokenId, uint256 expires);

    event ControllerAdded(address indexed controller);
    event ControllerRemoved(address indexed controller);

    // Authorises a controller, who can register and renew domains.
    function addController(address controller) external;

    // Revoke controller permission for an address.
    function removeController(address controller) external;

    // Returns the expiration timestamp of the specified label hash.
    function nameExpires(string memory rootDomain, string memory secondaryDomain) external view returns (uint256);

    function register(string memory rootDomainName, string memory secondaryDomainName,
        address owner, uint256 duration) external;

    function renew(uint256 tokenId, uint256 duration) external;

    function available(string memory rootDomain, string memory secondaryDomain)
        external pure returns (bool);

    function reclaim(string memory rootDomain, string memory secondaryDomain, address owner) external;
}

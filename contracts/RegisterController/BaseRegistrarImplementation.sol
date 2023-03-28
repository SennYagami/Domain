pragma solidity >=0.8.4;

import "./registry/DID.sol";
import "./interface/IBaseRegistrar.sol";
import "./token/ERC721/ERC721.sol";
import "./token/ERC721/extensions/IERC721Enumerable.sol";
import "./access/Ownable.sol";
import "./utils/Strings.sol";

interface BaseRegistrarImplementation {
    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) external;

    // Returns the expiration timestamp of the specified id.
    function nameExpires(uint256 id) external view returns (uint256);

    // Returns true iff the specified name is available for registration.
    function available(
        string memory rootDomain,
        string memory secondaryDomain
    ) external view returns (bool);

    /**
     * @dev Register a name.
     * @param rootDomain The root domain name.
     * @param secondaryDomain The secondary domain name.
     * @param owner The address that should own the registration.
     * @param duration Duration in seconds for the registration.
     */
    function register(
        string memory rootDomain,
        string memory secondaryDomain,
        address owner,
        uint256 duration
    ) external returns (uint256);

    /**
     * @dev Register a name, without modifying the registry.
     * @param rootDomain The root domain name.
     * @param secondaryDomain The secondary domain name.
     * @param owner The address that should own the registration.
     * @param duration Duration in seconds for the registration.
     */
    function registerOnly(
        string memory rootDomain,
        string memory secondaryDomain,
        address owner,
        uint256 duration
    ) external returns (uint256);

    function getTokenId(
        string memory rootName,
        string memory secondaryName
    ) external view returns (uint256 tokenId);

    function _register(
        string memory rootDomain,
        string memory secondaryDomain,
        address owner,
        uint256 duration,
        bool updateRegistry
    ) external returns (uint256);

    function renew(uint256 id, uint256 duration) external returns (uint256);

    /**
     * @dev Reclaim ownership of a name in SID, if you own it in the registrar.
     */
    function reclaim(uint256 id, address owner) external;
}

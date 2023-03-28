import "../registry/DID.sol";
import "./IBaseRegistrar.sol";
import "../interface/IERC721.sol";

interface IBaseRegistrar is IERC721 {
    event ControllerAdded(address indexed controller);
    event ControllerRemoved(address indexed controller);
    event NameMigrated(
        uint256 indexed id,
        address indexed owner,
        uint256 expires
    );
    event NameRegistered(
        string rootDomainName,
        string secondaryDomainName,
        address indexed owner,
        uint256 expires
    );

    event NameRenewed(uint256 tokenId, uint256 expires);

    // Authorises a controller, who can register and renew domains.
    function addController(address controller) external;

    // Revoke controller permission for an address.
    function removeController(address controller) external;

    // Returns the expiration timestamp of the specified label hash.
    function nameExpires(uint256 id) external view returns (uint256);

    // Returns true iff the specified name is available for registration.
    function available(
        string memory rootDomain,
        string memory secondaryDomain
    ) external view returns (bool);

    /**
     * @dev Register a name.
     */
    function register(
        string memory rootDomainName,
        string memory secondaryDomainName,
        address owner,
        uint duration
    ) external returns (uint256);

    function renew(
        string memory rootDomainName,
        string memory secondaryDomainName,
        uint duration
    ) external returns (uint256);

    /**
     * @dev Reclaim ownership of a name in SID, if you own it in the registrar.
     */
    function reclaim(uint256 id, address owner) external;
}

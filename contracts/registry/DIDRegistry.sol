pragma solidity >=0.8.4;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "./DID.sol";

/**
 * The DID registry contract.
 */
contract DIDRegistry is DID, Initializable, OwnableUpgradeable {
    struct Record {
        address owner;
    }

    mapping(bytes32 => Record) records;
    mapping(address => bool) public ownerControllers;
    mapping(string => bytes32) subRootDomainCreator; // .jay => nodehash(jay.did)
    mapping(address => bool) public creatorControllers;
    address resolver;

    modifier onlyOwnerController() {
        require(ownerControllers[msg.sender]);
        _;
    }

    modifier onlyCreatorController() {
        require(creatorControllers[msg.sender]);
        _;
    }

    /**
     * @dev Constructs a new DID registry.
     */
    // constructor() public {
    //     records[0x0].owner = msg.sender;
    // }

    function initialize() public initializer {
        __DID_init();
    }

    function __DID_init() internal onlyInitializing {
        __Ownable_init();
        __DID_init_unchained();
    }

    function __DID_init_unchained() internal onlyInitializing {
        subRootDomainCreator["did"] = keccak256("did");
    }

    /**
     * @dev Transfers ownership of a node to a new address. May only be called by the current owner of the node.
     * @param node The node to transfer ownership of.
     * @param owner The address of the new owner.
     */
    function setOwner(
        bytes32 node,
        address owner
    ) public virtual override onlyOwnerController {
        records[node].owner = owner;
        emit Transfer(node, owner);
    }

    /**
     * @dev Returns the address that owns the specified node.
     * @param node The specified node.
     * @return address of the owner.
     */
    function owner(
        bytes32 node
    ) public view virtual override returns (address) {
        address addr = records[node].owner;
        if (addr == address(this)) {
            return address(0x0);
        }

        return addr;
    }

    // Authorises a controller, who can register and renew domains.
    function addOwnerController(
        address controller
    ) external override onlyOwner {
        require(controller != address(0), "address can not be zero!");
        ownerControllers[controller] = true;
        emit OwnerControllerAdded(controller);
    }

    // Revoke controller permission for an address.
    function removeOwnerController(
        address controller
    ) external override onlyOwner {
        require(controller != address(0), "address can not be zero!");
        ownerControllers[controller] = false;
        emit OwnerControllerRemoved(controller);
    }

    // Authorises a controller, who can register and renew domains.
    function addCreatorController(
        address controller
    ) external override onlyOwner {
        require(controller != address(0), "address can not be zero!");
        creatorControllers[controller] = true;
        emit CreatorControllerAdded(controller);
    }

    // Revoke controller permission for an address.
    function removeCreatorController(
        address controller
    ) external override onlyOwner {
        require(controller != address(0), "address can not be zero!");
        creatorControllers[controller] = false;
        emit CreatorControllerRemoved(controller);
    }

    function setSubRootDomainCreator(
        string calldata subRootDomain,
        bytes32 node
    ) external onlyCreatorController {
        subRootDomainCreator[subRootDomain] = node;
        emit NewSubRootDomainCreator(node, subRootDomain);
    }

    function getSubRootDomainCreator(
        string calldata subRootDomain
    ) external view returns (bytes32) {
        return subRootDomainCreator[subRootDomain];
    }

    function checkRootDomainValidity(
        string calldata rootDomain
    ) external view returns (bool) {
        return subRootDomainCreator[rootDomain] != bytes32(0);
    }

    function setResolver(address _resolver) external onlyOwner {
        resolver = _resolver;
    }
}

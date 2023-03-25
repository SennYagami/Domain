pragma solidity >=0.8.4;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "./DONS.sol";

/**
 * The DO registry contract.
 */
contract DORegistry is DONS,  Initializable,OwnableUpgradeable {
    struct Record {
        address owner;
    }

    mapping(bytes32 => Record) records;
    mapping(address => bool) public controllers;
    mapping(string => bytes32) subRootDomainCreator; // .jay => nodehash(jay.do)


    modifier onlyController() {
        require(controllers[msg.sender]);
        _;
    }

    /**
     * @dev Constructs a new DO registry.
     */
    // constructor() public {
    //     records[0x0].owner = msg.sender;
    // }

    function initialize() public initializer {
        __DO_init();
    }

    function __DO_init() internal onlyInitializing {
        __Ownable_init();
        __DO_init_unchained();
    }

    function __DO_init_unchained() internal onlyInitializing {
        subRootDomainCreator["do"] = keccak256("do");
    }

    /**
     * @dev Transfers ownership of a node to a new address. May only be called by the current owner of the node.
     * @param node The node to transfer ownership of.
     * @param owner The address of the new owner.
     */
    function setOwner(
        bytes32 node,
        address owner
    ) public virtual override onlyController{
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
    function addController(address controller) external override onlyOwner {
        require(controller != address(0), "address can not be zero!");
        controllers[controller] = true;
        emit ControllerAdded(controller);
    }

    // Revoke controller permission for an address.
    function removeController(address controller) external override onlyOwner {
        require(controller != address(0), "address can not be zero!");
        controllers[controller] = false;
        emit ControllerRemoved(controller);
    }

    function setSubRootDomainCreator(
        string calldata subRootDomain,
        bytes32 node
    ) external onlyController {
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
}

pragma solidity >=0.8.4;

interface DID {
    // Logged when the owner of a node transfers ownership to a new account.
    event Transfer(bytes32 indexed node, address owner);

    event NewSubRootDomainCreator(
        bytes32 indexed creator,
        string indexed subRootDomain
    );
    event OwnerControllerAdded(address indexed controller);
    event OwnerControllerRemoved(address indexed controller);

    event CreatorControllerAdded(address indexed controller);
    event CreatorControllerRemoved(address indexed controller);
    event NewResolver(address indexed resolver);

    function setOwner(bytes32 node, address owner) external;

    function getOwner(bytes32 node) external view returns (address);

    function addOwnerController(address controller) external;

    function removeOwnerController(address controller) external;

    function addCreatorController(address controller) external;

    function removeCreatorController(address controller) external;

    function setSubRootDomainCreator(
        string calldata subRootDomain,
        bytes32 node
    ) external;

    function getSubRootDomainCreator(
        string calldata subRootDomain
    ) external view returns (bytes32);

    // check if the root domain has been registered
    function checkRootDomainValidity(
        string calldata rootDomainName
    ) external view returns (bool);
}

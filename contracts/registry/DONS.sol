pragma solidity >=0.8.4;

interface DONS {

    // Logged when the owner of a node transfers ownership to a new account.
    event Transfer(bytes32 indexed node, address owner);

    event NewSubRootDomainCreator(
        bytes32 indexed creator,
        string indexed subRootDomain
    );
    event ControllerAdded(address indexed controller);
    event ControllerRemoved(address indexed controller);

    function setOwner(bytes32 node, address owner) external;

    function owner(bytes32 node) external view returns (address);

    function addController(address controller) external;
    function removeController(address controller) external;

    function setSubRootDomainCreator(
        string calldata subRootDomain,
        bytes32 node
    ) external;

    function getSubRootDomainCreator(
        string calldata subRootDomain
    ) external view returns (bytes32);

    // check if the root domain has been registered
    function checkRootDomainValidity(string calldata rootDomainName) external view returns (bool);
}

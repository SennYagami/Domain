// SPDX-License-Identifier: NO LICENSE
pragma solidity ^0.8.17;


import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

import "./IRegistrar.sol";
import "./IRegistry.sol";
import "../utils/ERC20Recoverable.sol";
import "../utils/StringUtils.sol";

error NameNotAvailable(string name);
error DurationTooShort(uint256 duration);

contract Registrar is IRegistrar, ERC721, Ownable, ERC20Recoverable  {

    //using StringUtils for string;

    // A map of expiry times
    mapping(uint256 => uint256) expiries;
    // The ENS registry
    address public ENS;


    // A map of addresses that are authorised to register and renew names.
    mapping(address => bool) public controllers;
    uint256 public constant GRACE_PERIOD = 30 days;
    bytes4 private constant INTERFACE_META_ID = bytes4(keccak256("supportsInterface(bytes4)"));
    bytes4 private constant ERC721_ID =
        bytes4(
            keccak256("balanceOf(address)") ^
            keccak256("ownerOf(uint256)") ^
            keccak256("approve(address,uint256)") ^
            keccak256("getApproved(uint256)") ^
            keccak256("setApprovalForAll(address,bool)") ^
            keccak256("isApprovedForAll(address,address)") ^
            keccak256("transferFrom(address,address,uint256)") ^
            keccak256("safeTransferFrom(address,address,uint256)") ^
            keccak256("safeTransferFrom(address,address,uint256,bytes)")
        );
    bytes4 private constant RECLAIM_ID = bytes4(keccak256("reclaim(uint256,address)"));

    function _isApprovedOrOwner(
        address spender,
        uint256 tokenId
    ) internal view override returns (bool) {
        address owner = ownerOf(tokenId);
        return (spender == owner ||
        getApproved(tokenId) == spender ||
        isApprovedForAll(owner, spender));
    }

    constructor(address _ens) ERC721("", "") {
        ENS = _ens;
    }

    modifier onlyController() {
        require(controllers[msg.sender]);
        _;
    }

    function available(string memory rootDomain, string memory secondaryDomain)
        external pure returns (bool) {
        return (_calTokenId(rootDomain, secondaryDomain) != 0);
    }

    function ownerOf(
        string memory rootDomain, string memory secondaryDomain
    ) public view returns (address) {
        uint256 tokenId = _calTokenId(rootDomain, secondaryDomain);
        require(expiries[tokenId] > block.timestamp);
        return super.ownerOf(tokenId);
    }

    function addController(address controller) external override onlyOwner {
        controllers[controller] = true;
        emit ControllerAdded(controller);
    }

    function removeController(address controller) external override onlyOwner {
        controllers[controller] = false;
        emit ControllerRemoved(controller);
    }

    function nameExpires(string memory rootDomain, string memory secondaryDomain) public view override returns (uint256) {
        return expiries[_calTokenId(rootDomain, secondaryDomain)];
    }

    function register(string memory rootDomainName, string memory secondaryDomainName,
        address owner, uint256 duration) external {
        _register(rootDomainName, secondaryDomainName, owner, duration, true);
    }

    function registerOnly(string memory rootDomainName, string memory secondaryDomainName,
        address owner, uint256 duration) external {
        _register(rootDomainName, secondaryDomainName, owner, duration, false);
    }

    function renew(string memory rootDomainName, string memory secondaryDomainName, uint256 duration) external onlyController {

        uint256 tokenId = _calTokenId(rootDomainName, secondaryDomainName);

        require(expiries[tokenId] + GRACE_PERIOD >= block.timestamp); // Name must be registered here or in grace period
        require(
            expiries[tokenId] + duration + GRACE_PERIOD > duration + GRACE_PERIOD
        );

        expiries[tokenId] += duration;
        emit NameRenewed(rootDomainName, secondaryDomainName, expiries[tokenId]);
    }

    function reclaim(string memory rootDomain, string memory secondaryDomain, address owner) external {
        uint256 tokenId = _calTokenId(rootDomain, secondaryDomain);
        require(_isApprovedOrOwner(msg.sender, tokenId));
        IRegistry(ENS).setOwner(tokenId, owner);
    }

    function supportsInterface(
        bytes4 interfaceID
    ) public pure override(ERC721, IERC165) returns (bool) {
        return
        interfaceID == INTERFACE_META_ID ||
        interfaceID == ERC721_ID ||
        interfaceID == RECLAIM_ID;
    }

    function _calTokenId(string memory rootDomainName, string memory secondaryDomainName) internal pure returns(uint256 tokenId) {
        bytes32 firstHash = keccak256(abi.encode(address(0), keccak256(bytes(rootDomainName))));
        tokenId = uint256(keccak256(abi.encode(firstHash, keccak256(bytes(secondaryDomainName)))));
    }

    function _register(string memory rootDomainName, string memory secondaryDomainName,
        address owner, uint256 duration, bool updateRegistry) internal onlyController {

        require(IRegistry(ENS).checkRootDomainValidity(rootDomainName), "INVALID_ROOT_DOMAIN");

        uint256 tokenId = _calTokenId(rootDomainName, secondaryDomainName);
        require(_available(tokenId), "TOKEN_ID_IS_UNAVAILABLE");

        require(
            block.timestamp + duration + GRACE_PERIOD >
            block.timestamp + GRACE_PERIOD
        );

        uint256 expiry = block.timestamp + duration;
        expiries[tokenId] = expiry;

        if (_exists(tokenId)) {
            // Name was previously owned, and expired
            _burn(tokenId);
        }
        _mint(owner, tokenId);

        if (updateRegistry) {
            IRegistry(ENS).setOwner(tokenId, owner);
        }

        emit NameRegistered(rootDomainName, secondaryDomainName, owner, expiry);
    }

    function _available(uint256 id) internal view returns (bool) {
        // Not available if it's registered here or in its grace period.
        return expiries[id] + GRACE_PERIOD < block.timestamp;
    }


}

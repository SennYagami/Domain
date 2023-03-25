// SPDX-License-Identifier: NO LICENSE
pragma solidity ^0.8.17;


import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

import "./IRegistrar.sol";
import "./IRegistry.sol";
import "./IPriceOracle.sol";
import "./IENS.sol";
import "./IReverseRegistrar.sol";
import "../utils/ERC20Recoverable.sol";
import "../utils/StringUtils.sol";

error CommitmentTooNew(bytes32 commitment);
error CommitmentTooOld(bytes32 commitment);
error NameNotAvailable(string name);
error DurationTooShort(uint256 duration);
error ResolverRequiredWhenDataSupplied();
error UnexpiredCommitmentExists(bytes32 commitment);
error InsufficientValue();
error Unauthorised(bytes32 node);
error MaxCommitmentAgeTooLow();
error MaxCommitmentAgeTooHigh();

contract Registrar is IRegistrar, ERC721, Ownable, ERC20Recoverable  {

    using StringUtils for string;

    // A map of expiry times
    mapping(uint256 => uint256) expiries;
    mapping(uint256 => string) domainId2Domain;
    mapping(string => uint256) domain2DomainId;
    // The ENS registry
    address public ens;

    uint256 public constant MIN_REGISTRATION_DURATION = 28 days;
    uint64 private constant MAX_EXPIRY = type(uint64).max;
    IPriceOracle public immutable prices;
    uint256 public immutable minCommitmentAge;
    uint256 public immutable maxCommitmentAge;
    address public immutable reverseRegistrar;
    mapping(bytes32 => uint256) public commitments;

    // The namehash of the TLD this registrar owns (eg, .eth)
    //bytes32 public baseNode;

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

    constructor(address _ens, IPriceOracle _prices, uint256 _minCommitmentAge,
        uint256 _maxCommitmentAge, address _reverseRegistrar) ERC721("", "") {
        if (_maxCommitmentAge <= _minCommitmentAge) {
            revert MaxCommitmentAgeTooLow();
        }

        if (_maxCommitmentAge > block.timestamp) {
            revert MaxCommitmentAgeTooHigh();
        }

        ens = _ens;
        prices = _prices;
        minCommitmentAge = _minCommitmentAge;
        maxCommitmentAge = _maxCommitmentAge;
        reverseRegistrar = _reverseRegistrar;
    }



    //modifier live() {
    //    require(ens.owner(baseNode) == address(this));
    //    _;
    //}

    modifier onlyController() {
        require(controllers[msg.sender]);
        _;
    }

    function rentPrice(
        string memory domain,
        uint256 duration
    ) public view returns (IPriceOracle.Price memory price) {
        price = prices.price(domain, nameExpires(domain), duration);
    }

    function valid(string memory name) public pure returns (bool) {
        return name.strlen() >= 3;
    }

    function available(string memory name) external view returns (bool) {
        return valid(name) && (domain2DomainId[name] != 0);
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

    function setResolver(string memory rootDomain, address resolver) external override onlyOwner {
        IENS(ens).setResolver(rootDomain, resolver);
    }

    function nameExpires(string memory domain) public view override returns (uint256) {
        return expiries[domain2DomainId[domain]];
    }

    function _available(uint256 id) internal view returns (bool) {
        // Not available if it's registered here or in its grace period.
        return expiries[id] + GRACE_PERIOD < block.timestamp;
    }

    function makeCommitment(
        string memory name,
        address owner,
        uint256 duration,
        bytes32 secret,
        address resolver,
        bytes[] calldata data,
        bool reverseRecord,
        uint16 ownerControlledFuses
    ) public pure override returns (bytes32) {
        bytes32 label = keccak256(bytes(name));
        if (data.length > 0 && resolver == address(0)) {
            revert ResolverRequiredWhenDataSupplied();
        }
        return
        keccak256(
            abi.encode(
                label,
                owner,
                duration,
                secret,
                resolver,
                data,
                reverseRecord,
                ownerControlledFuses
            )
        );
    }

    function commit(bytes32 commitment) public override {
        if (commitments[commitment] + maxCommitmentAge >= block.timestamp) {
            revert UnexpiredCommitmentExists(commitment);
        }
        commitments[commitment] = block.timestamp;
    }


    function _calTokenId(string memory rootDomainName, string memory secondaryDomainName) internal pure returns(uint256 tokenId) {


        bytes32 firstHash = keccak256(abi.encode(address(0), keccak256(bytes(rootDomainName))));
        tokenId = uint256(keccak256(abi.encode(firstHash, keccak256(bytes(secondaryDomainName)))));
    }

    function _consumeCommitment(
        string memory name,
        uint256 duration,
        bytes32 commitment
    ) internal {
        // Require an old enough commitment.
        if (commitments[commitment] + minCommitmentAge > block.timestamp) {
            revert CommitmentTooNew(commitment);
        }

        // If the commitment is too old, or the name is registered, stop
        if (commitments[commitment] + maxCommitmentAge <= block.timestamp) {
            revert CommitmentTooOld(commitment);
        }
        if (!_available(domain2DomainId[name])) {
            revert NameNotAvailable(name);
        }

        delete (commitments[commitment]);

        if (duration < MIN_REGISTRATION_DURATION) {
            revert DurationTooShort(duration);
        }
    }

    //todo:
    //function _setRecords(
    //    address resolverAddress,
    //    bytes32 label,
    //    bytes[] calldata data
    //) internal {
    //    // use hardcoded .eth namehash
    //    bytes32 nodehash = keccak256(abi.encodePacked(ETH_NODE, label));
    //    Resolver resolver = Resolver(resolverAddress);
    //    resolver.multicallWithNodeCheck(nodehash, data);
    //}

    function _setReverseRecord(
        string memory name,
        address resolver,
        address owner
    ) internal {
        IReverseRegistrar(reverseRegistrar).setNameForAddr(
            msg.sender,
            owner,
            resolver,
            name
        );
    }

    function register(string memory rootDomainName, string memory secondaryDomainName, address owner,
        uint256 duration, bytes32 secret, address resolver, bytes[] calldata data,
        bool reverseRecord, uint16 ownerControlledFuses) public payable {

        require(IRegistry(ens).checkRootDomainValidity(rootDomainName), "INVALID_ROOT_DOMAIN");

        string memory domain;
        if (secondaryDomainName.strlen() == 0) {
            domain = rootDomainName;
        } else {
            domain = secondaryDomainName;
        }

        IPriceOracle.Price memory price = rentPrice(domain, duration);
        if (msg.value < price.base + price.premium) {
            revert InsufficientValue();
        }

        _consumeCommitment(
            domain,
            duration,
            makeCommitment(
                domain,
                owner,
                duration,
                secret,
                resolver,
                data,
                reverseRecord,
                ownerControlledFuses
            )
        );


        uint256 tokenId = _calTokenId(rootDomainName, secondaryDomainName);
        require(_available(tokenId), "TOKEN_ID_IS_UNAVAILABLE");

        require(
            block.timestamp + duration + GRACE_PERIOD >
            block.timestamp + GRACE_PERIOD
        );

        if (data.length > 0) {
            //_setRecords(resolver, keccak256(bytes(name)), data);
        }

        if (reverseRecord) {
            _setReverseRecord(domain, resolver, msg.sender);
        }

        uint256 expiry = block.timestamp + duration;
        expiries[tokenId] = expiry;
        domain2DomainId[domain] = tokenId;
        domainId2Domain[tokenId] = domain;

        if (_exists(tokenId)) {
            // Name was previously owned, and expired
            _burn(tokenId);
        }
        _mint(owner, tokenId);
        IRegistry(ens).setOwner(secondaryDomainName, owner);

        if (msg.value > (price.base + price.premium)) {
            payable(msg.sender).transfer(
                msg.value - (price.base + price.premium)
            );
        }

        emit NameRegistered(rootDomainName, secondaryDomainName, owner, price.base+price.premium, expiry);
    }

    function renew(string memory rootDomainName, string memory secondaryDomainName, uint256 duration) external payable {

        uint256 tokenId = _calTokenId(rootDomainName, secondaryDomainName);

        IPriceOracle.Price memory price = rentPrice(domainId2Domain[tokenId], duration);
        if (msg.value < price.base) {
            revert InsufficientValue();
        }

        require(expiries[tokenId] + GRACE_PERIOD >= block.timestamp); // Name must be registered here or in grace period
        require(
            expiries[tokenId] + duration + GRACE_PERIOD > duration + GRACE_PERIOD
        );

        expiries[tokenId] += duration;
        emit NameRenewed(rootDomainName, secondaryDomainName, msg.value, expiries[tokenId]);
    }

    function withdraw() public {
        payable(owner()).transfer(address(this).balance);
    }


    function supportsInterface(
        bytes4 interfaceID
    ) public pure override(ERC721, IERC165) returns (bool) {
        return
        interfaceID == INTERFACE_META_ID ||
        interfaceID == ERC721_ID ||
        interfaceID == RECLAIM_ID;
    }
}

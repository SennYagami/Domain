// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import "./BaseRegistrarImplementation.sol";
import "./utils/StringUtils.sol";
import "./resolvers/Resolver.sol";
import "./referral/IReferralHub.sol";
import "./price-oracle/ISidPriceOracle.sol";
import "./interface/IBNBRegistrarController.sol";
import "./access/Ownable.sol";
import "./utils/introspection/IERC165.sol";
import "./utils/Address.sol";

/**
 * @dev Registrar with giftcard support
 *
 */
contract BNBRegistrarControllerV9 is Ownable {
    using StringUtils for *;

    uint256 public constant MIN_REGISTRATION_DURATION = 365 days;

    bytes4 private constant INTERFACE_META_ID =
        bytes4(keccak256("supportsInterface(bytes4)"));
    bytes4 private constant COMMITMENT_CONTROLLER_ID =
        bytes4(
            keccak256("rentPrice(string,uint256)") ^
                keccak256("available(string)") ^
                keccak256("makeCommitment(string,address,bytes32)") ^
                keccak256("commit(bytes32)") ^
                keccak256("register(string,address,uint256,bytes32)") ^
                keccak256("renew(string,uint256)")
        );

    bytes4 private constant COMMITMENT_WITH_CONFIG_CONTROLLER_ID =
        bytes4(
            keccak256(
                "registerWithConfig(string,address,uint256,bytes32,address,address)"
            ) ^
                keccak256(
                    "makeCommitmentWithConfig(string,address,bytes32,address,address)"
                )
        );

    BaseRegistrarImplementation base;
    ISidPriceOracle prices;
    IReferralHub referralHub;
    uint256 public minCommitmentAge;
    uint256 public maxCommitmentAge;
    address immutable resolver;

    mapping(bytes32 => uint256) public commitments;

    error BadSignature();

    struct WhitelistRegister {
        address user;
        uint256 secondaryDomainNameLength;
        uint256 nonce;
        uint256 duration;
    }

    mapping(uint256 => bool) whitelistUsed;

    event NameRegistered(
        string rootName,
        string secondaryName,
        uint256 indexed tokenId,
        address indexed owner,
        uint256 cost,
        uint256 expires
    );
    event NameRenewed(uint256 indexed tokenId, uint256 cost, uint256 expires);
    event NewPriceOracle(address indexed oracle);

    constructor(
        BaseRegistrarImplementation _base,
        ISidPriceOracle _prices,
        IReferralHub _referralHub,
        uint256 _minCommitmentAge,
        uint256 _maxCommitmentAge,
        address resolverAddress
    ) {
        require(_maxCommitmentAge > _minCommitmentAge);
        base = _base;
        prices = _prices;
        referralHub = _referralHub;
        minCommitmentAge = _minCommitmentAge;
        maxCommitmentAge = _maxCommitmentAge;
        resolver = resolverAddress;
    }

    function getTokenId(
        string memory rootName,
        string memory secondaryName
    ) public pure returns (uint256 tokenId) {
        bytes32 firstHash = keccak256(
            abi.encode(address(0), keccak256(bytes(rootName)))
        );

        tokenId = uint256(
            keccak256(abi.encode(firstHash, keccak256(bytes(secondaryName))))
        );
    }

    function rentPrice(
        string memory rootName,
        string memory secondaryName,
        uint256 duration
    ) public view returns (ISidPriceOracle.Price memory price) {
        uint256 tokenId = getTokenId(rootName, secondaryName);
        price = prices.domainPriceInBNB(
            rootName,
            secondaryName,
            base.nameExpires(uint256(tokenId)),
            duration
        );
    }

    function valid(string memory name) public pure returns (bool) {
        // check unicode rune count, if rune count is >=3, byte length must be >=3.
        if (name.strlen() < 3) {
            return false;
        }

        bytes memory nb = bytes(name);

        for (uint i; i < nb.length; i++) {
            bytes1 char = nb[i];

            if (
                !(char >= 0x30 && char <= 0x39) && //9-0
                !(char >= 0x41 && char <= 0x5A) && //A-Z
                !(char >= 0x61 && char <= 0x7A) && //a-z
                !(char == 0x2E) && //.
                !(char == 0x5F) // _
            ) return false;
        }

        return true;
    }

    function available(
        string memory rootName,
        string memory secondaryName
    ) public view returns (bool) {
        uint256 tokenId = getTokenId(rootName, secondaryName);
        return valid(secondaryName) && base.available(rootName, secondaryName);
    }

    function makeCommitment(
        string memory rootName,
        string memory secondaryName,
        address owner,
        bytes32 secret
    ) public pure returns (bytes32) {
        return
            makeCommitmentWithConfig(
                rootName,
                secondaryName,
                owner,
                secret,
                address(0)
            );
    }

    function makeCommitmentWithConfig(
        string memory rootName,
        string memory secondaryName,
        address owner,
        bytes32 secret,
        address addr
    ) public pure returns (bytes32) {
        uint256 tokenId = getTokenId(rootName, secondaryName);
        return keccak256(abi.encodePacked(tokenId, owner, secret, addr));
    }

    function commit(bytes32 commitment) public {
        require(commitments[commitment] + maxCommitmentAge < block.timestamp);
        commitments[commitment] = block.timestamp;
    }

    function register(
        string calldata rootName,
        string calldata secondaryName,
        address owner,
        uint256 duration,
        bytes32 secret
    ) external payable {
        registerWithConfig(
            rootName,
            secondaryName,
            owner,
            duration,
            secret,
            address(0),
            bytes32(0)
        );
    }

    function registerWithConfig(
        string memory rootName,
        string memory secondaryName,
        address owner,
        uint256 duration,
        bytes32 secret,
        address addr,
        bytes32 nodehash
    ) public payable {
        bytes32 commitment = makeCommitmentWithConfig(
            rootName,
            secondaryName,
            owner,
            secret,
            addr
        );

        uint256 cost = _consumeCommitment(
            rootName,
            secondaryName,
            duration,
            commitment
        );

        uint256 tokenId = getTokenId(rootName, secondaryName);

        uint256 expires;
        if (addr != address(0)) {
            // Set this contract as the (temporary) owner, giving it
            // permission to set up the resolver.
            expires = base.register(
                rootName,
                secondaryName,
                address(this),
                duration
            );

            bytes32 nodeHash = bytes32(tokenId);

            // Configure the resolver
            if (addr != address(0)) {
                Resolver(resolver).setAddr(nodehash, addr);
            }

            // Now transfer full ownership to the expeceted owner
            base.reclaim(tokenId, owner);
            base.transferFrom(address(this), owner, tokenId);
        } else {
            expires = base.register(rootName, secondaryName, owner, duration);
        }

        emit NameRegistered(
            rootName,
            secondaryName,
            tokenId,
            owner,
            cost,
            expires
        );

        //Check is eligible for referral program
        if (nodehash != bytes32(0)) {
            (bool isEligible, address resolvedAddress) = referralHub
                .isReferralEligible(nodehash);
            if (isEligible && nodehash != bytes32(0)) {
                referralHub.addNewReferralRecord(nodehash);
                (uint256 referrerFee, uint256 referreeFee) = referralHub
                    .getReferralCommisionFee(cost, nodehash);
                if (referrerFee > 0) {
                    referralHub.deposit{value: referrerFee}(resolvedAddress);
                }
                cost = cost - referreeFee;
            }
        }

        // Refund any extra payment
        if (msg.value > cost) {
            payable(msg.sender).transfer(msg.value - cost);
        }
    }

    function renew(
        string calldata rootName,
        string calldata secondaryName,
        uint256 duration
    ) public payable {
        ISidPriceOracle.Price memory price;

        price = rentPrice(rootName, secondaryName, duration);

        uint256 cost = (price.base + price.premium);
        require(msg.value >= cost);
        uint256 tokenId = getTokenId(rootName, secondaryName);
        uint256 expires = base.renew(tokenId, duration);

        // Refund any extra payment
        if (msg.value > cost) {
            payable(msg.sender).transfer(msg.value - cost);
        }

        emit NameRenewed(tokenId, cost, expires);
    }

    function setPriceOracle(ISidPriceOracle _prices) public onlyOwner {
        prices = _prices;
        emit NewPriceOracle(address(prices));
    }

    function setCommitmentAges(
        uint256 _minCommitmentAge,
        uint256 _maxCommitmentAge
    ) public onlyOwner {
        minCommitmentAge = _minCommitmentAge;
        maxCommitmentAge = _maxCommitmentAge;
    }

    function withdraw() public onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    function supportsInterface(
        bytes4 interfaceID
    ) external pure returns (bool) {
        return
            interfaceID == INTERFACE_META_ID ||
            interfaceID == COMMITMENT_CONTROLLER_ID ||
            interfaceID == COMMITMENT_WITH_CONFIG_CONTROLLER_ID;
    }

    function _consumeCommitment(
        string memory rootName,
        string memory secondaryName,
        uint256 duration,
        bytes32 commitment
    ) internal returns (uint256) {
        // Require a valid commitment
        require(commitments[commitment] + minCommitmentAge <= block.timestamp);
        // If the commitment is too old, or the name is registered, stop
        require(commitments[commitment] + maxCommitmentAge > block.timestamp);

        require(available(rootName, secondaryName), "D205");

        delete (commitments[commitment]);

        ISidPriceOracle.Price memory price;
        price = rentPrice(rootName, secondaryName, duration);

        uint256 cost = (price.base + price.premium);
        require(duration >= MIN_REGISTRATION_DURATION);
        require(msg.value >= cost);
        return cost;
    }

    function whitelistRegister(
        bytes calldata message,
        bytes calldata signature,
        string memory rootName,
        string memory secondaryName,
        address addr
    ) public {
        // Declare r, s, and v signature parameters.
        bytes32 r;
        bytes32 s;
        uint8 v;

        bytes32 hash = keccak256(message);

        if (signature.length == 65) {
            (r, s) = abi.decode(signature, (bytes32, bytes32));
            v = uint8(signature[64]);

            // Ensure v value is properly formatted.
            if (v != 27 && v != 28) {
                revert BadSignature();
            }
        } else {
            revert BadSignature();
        }

        address signer = ecrecover(hash, v, r, s);
        require(signer == owner(), "D201");

        WhitelistRegister memory whitelistRegister = abi.decode(
            message,
            (WhitelistRegister)
        );

        require(whitelistUsed[whitelistRegister.nonce] == false, "D202");
        whitelistUsed[whitelistRegister.nonce] = true;

        address user = whitelistRegister.user;
        require(_msgSender() == user, "D203");

        require(
            secondaryName.strlen() ==
                whitelistRegister.secondaryDomainNameLength,
            "D204"
        );

        require(available(rootName, secondaryName), "D205");

        uint256 tokenId = getTokenId(rootName, secondaryName);

        uint256 expires;
        if (addr != address(0)) {
            // Set this contract as the (temporary) owner, giving it
            // permission to set up the resolver.
            expires = base.register(
                rootName,
                secondaryName,
                address(this),
                whitelistRegister.duration
            );

            bytes32 nodeHash = bytes32(tokenId);

            // Configure the resolver
            if (addr != address(0)) {
                Resolver(resolver).setAddr(nodeHash, addr);
            }

            // Now transfer full ownership to the expeceted owner
            base.reclaim(tokenId, _msgSender());
            base.transferFrom(address(this), _msgSender(), tokenId);
        } else {
            expires = base.register(
                rootName,
                secondaryName,
                _msgSender(),
                whitelistRegister.duration
            );
        }

        emit NameRegistered(
            rootName,
            secondaryName,
            tokenId,
            _msgSender(),
            0,
            expires
        );
    }
}

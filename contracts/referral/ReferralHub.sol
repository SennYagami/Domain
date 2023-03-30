// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import "./IReferralHub.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../registry/DID.sol";
import "../resolvers/profiles/AddrResolver.sol";
import "../resolvers/profiles/NameResolver.sol";

contract ReferralHub is IReferralHub, Ownable {
    // ReferralHub controllers that can update referral count and related states.
    mapping(address => bool) public controllers;

    // Commission configuration
    struct Comission {
        // The number of minimum referrals that is required for the rate.
        uint256 minimumReferralCount;
        // Percentage of registration fee that will be deposited to referrer.
        uint256 referrer;
        // Percentage of registration fee that will be discounted to referee.
        uint256 referee;
    }
    //map comission chart to a level
    mapping(uint256 => Comission) public comissionCharts;
    // map from refferral domain name nodehash to the number of referrals.
    mapping(bytes32 => uint256) public referralCount;
    // map address to the amount of bonus.
    mapping(address => uint256) public referralBalance;
    // Map partner's domain's nodehash to customized commission rate.
    mapping(bytes32 => Comission) public partnerComissionCharts;

    DID immutable did;

    constructor(DID _did) {
        did = _did;
        comissionCharts[1] = Comission(0, 5, 0);
        comissionCharts[2] = Comission(30, 10, 0);
        comissionCharts[3] = Comission(100, 12, 0);
        comissionCharts[4] = Comission(500, 15, 0);
        comissionCharts[5] = Comission(100000000, 15, 0);
        comissionCharts[6] = Comission(100000000, 15, 0);
        comissionCharts[7] = Comission(100000000, 15, 0);
        comissionCharts[8] = Comission(100000000, 15, 0);
        comissionCharts[9] = Comission(100000000, 15, 0);
        comissionCharts[10] = Comission(100000000, 15, 0);
    }

    modifier onlyController() {
        require(controllers[msg.sender], "Not a authorized controller");
        _;
    }

    modifier validLevel(uint256 _level) {
        require(_level >= 1 && _level <= 10, "Invalid level");
        _;
    }

    function getNodehash(string calldata name, string calldata tld) public pure returns (bytes32) {
        bytes32 nameHash = keccak256(bytes(name));
        bytes32 tldHash = keccak256(abi.encodePacked(bytes32(0), keccak256(bytes(tld))));
        return keccak256(abi.encodePacked(tldHash, nameHash));
    }

    function isReferralEligible(bytes32 nodeHash) external view override returns (bool, address) {
        address resolverAddress = did.getResolver();
        if (resolverAddress == address(0)) {
            return (false, address(0));
        }
        AddrResolver resolver = AddrResolver(resolverAddress);
        address resolvedAddress = resolver.addr(nodeHash);

        address acceptAddress = resolver.commissionAcceptAddress(nodeHash);
        if (acceptAddress != address(0)) {
            resolvedAddress = acceptAddress;
        }

        return (true, resolvedAddress);
    }

    function isPartner(bytes32 nodeHash) public view returns (bool) {
        return partnerComissionCharts[nodeHash].referrer > 0 || partnerComissionCharts[nodeHash].referee > 0;
    }

    function getReferralCommisionFee(uint256 price, bytes32 nodeHash) public view returns (uint256, uint256) {
        uint256 referrerRate = 0;
        uint256 refereeRate = 0;
        uint256 level = 1;
        if (isPartner(nodeHash)) {
            referrerRate = partnerComissionCharts[nodeHash].referrer;
            refereeRate = partnerComissionCharts[nodeHash].referee;
        } else {
            (level, referrerRate, refereeRate) = _getComissionChart(referralCount[nodeHash]);
        }
        uint256 referrerFee = (price * referrerRate) / 100;
        uint256 refereeFee = (price * refereeRate) / 100;
        return (referrerFee, refereeFee);
    }

    function setPartnerComissionChart(
        string calldata name,
        string calldata tld,
        uint256 minimumReferralCount,
        uint256 referrerRate,
        uint256 refereeRate
    ) external onlyOwner {
        bytes32 nodeHash = getNodehash(name, tld);
        partnerComissionCharts[nodeHash] = Comission(minimumReferralCount, referrerRate, refereeRate);
    }

    function addNewReferralRecord(bytes32 referrerNodeHash) external override onlyController {
        referralCount[referrerNodeHash] += 1;
        emit NewReferralRecord(referrerNodeHash);
    }

    function _getReferralCount(bytes32 referrerNodeHash) internal view returns (uint256) {
        return referralCount[referrerNodeHash];
    }

    function _getComissionChart(uint256 referralAmount)
        internal
        view
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        uint256 curLevel = 1;
        uint256 referrerRate;
        uint256 refereeRate;
        uint256 level;
        while (referralAmount >= comissionCharts[curLevel].minimumReferralCount) {
            referrerRate = comissionCharts[curLevel].referrer;
            refereeRate = comissionCharts[curLevel].referee;
            level = curLevel;
            curLevel += 1;
        }
        return (level, referrerRate, refereeRate);
    }

    function getReferralDetails(bytes32 referrerNodeHash)
        external
        view
        override
        returns (
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        uint256 referralNum = _getReferralCount(referrerNodeHash);
        (uint256 level, uint256 referrerRate, uint256 refereeRate) = _getComissionChart(referralNum);
        return (referralNum, level, referrerRate, refereeRate);
    }

    function setComissionChart(
        uint256 level,
        uint256 minimumAmount,
        uint256 referrerRate,
        uint256 refereeRate
    ) external onlyOwner validLevel(level) {
        comissionCharts[level] = Comission(minimumAmount, referrerRate, refereeRate);
    }

    function deposit(address _referrer) external payable onlyController{
        require(msg.value > 0, "Invalid amount");
        referralBalance[_referrer] += msg.value;
        emit depositRecord(_referrer, msg.value);
    }

    function withdraw() external {
        uint256 amount = referralBalance[msg.sender];
        require(amount > 0, "Insufficient balance");
        referralBalance[msg.sender] = 0;
        payable(msg.sender).transfer(amount);
        emit withdrawRecord(msg.sender, amount);
    }

    function addController(address controller) external override onlyOwner {
        controllers[controller] = true;
        emit ControllerAdded(controller);
    }

    function removeController(address controller) external override onlyOwner {
        controllers[controller] = false;
        emit ControllerRemoved(controller);
    }
}

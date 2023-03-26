pragma solidity >=0.8.4;

import "./IPriceOracle.sol";

interface IDidRegistrarController {
    function rentPrice(
        string memory rootName,
        string memory secondaryName,
        uint256 duration
    ) external returns (IPriceOracle.Price memory);

    function available(
        string calldata rootName,
        string calldata secondaryName
    ) external returns (bool);

    function makeCommitment(
        string calldata rootName,
        string calldata secondaryName,
        address owner,
        bytes32 secret
    ) external returns (bytes32);

    function commit(bytes32) external;

    function register(
        string calldata rootName,
        string calldata secondaryName,
        address owner,
        uint256 duration,
        bytes32 secret
    ) external payable;

    function renew(
        string calldata rootName,
        string calldata secondaryName,
        uint256 duration
    ) external payable;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

interface IDidPriceOracle {
    struct Price {
        uint256 base;
        uint256 premium;
    }

    function domainPriceInMatic(
        string calldata rootName,
        string calldata secondaryName,
        uint256 duration
    ) external view returns (Price calldata);

}

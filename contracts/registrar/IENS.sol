// SPDX-License-Identifier: NO LICENSE
pragma solidity ^0.8.17;

interface IENS {
    function setResolver(string memory domain, address resolver) external;

}
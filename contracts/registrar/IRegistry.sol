// SPDX-License-Identifier: NO LICENSE
pragma solidity ^0.8.17;

interface IRegistry {
    function checkRootDomainValidity(string memory rootDomainName) external returns(bool);

    function setOwner(uint256 tokenId, address owner) external;

}
// SPDX-License-Identifier: NO LICENSE
pragma solidity ^0.8.17;

interface IRegistry {
    function checkRootDomainValidity(string memory rootDomainName) external returns(bool);

    function setOwner(string memory domainName, address owner) external;

}
// SPDX-License-Identifier: NO LICENSE
pragma solidity ^0.8.17;

interface IReverseRegistrar {

    function setNameForAddr(
        address addr,
        address owner,
        address resolver,
        string memory name
    ) external returns (bytes32) ;

}
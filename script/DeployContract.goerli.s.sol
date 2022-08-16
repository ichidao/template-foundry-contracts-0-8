// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

import {Script} from "forge-std/Script.sol";

import {Contract} from "src/contracts/Contract.sol";

/// @notice Deploy the Contract contract
contract DeployContract is Script {

    /// @notice The main script entrypoint
    /// @return c The deployed contract
    function run() external returns (Contract c) {
        vm.startBroadcast();
        c = new Contract();
        vm.stopBroadcast();
    }
}

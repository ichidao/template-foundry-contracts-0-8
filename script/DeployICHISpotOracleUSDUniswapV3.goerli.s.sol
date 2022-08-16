// SPDX-License-Identifier: MIT

pragma solidity 0.8.16;

import {Script} from "forge-std/Script.sol";

import {ICHISpotOracleUSDUniswapV3} from "src/contracts/ICHISpotOracleUSDUniswapV3.sol";

/// @notice Deploy the ICHISpotOracleUSDUniswapV3 contract
contract DeployICHISpotOracleUSDUniswapV3 is Script {
    address constant ICHI_V2_ADDRESS = 0x9b0757aCaCA5160CEBc3D16769E4f2bCe71BFbF2;

    /// @notice The main script entrypoint
    /// @return oracle The deployed contract
    function run() external returns (ICHISpotOracleUSDUniswapV3 oracle) {
        vm.startBroadcast();
        oracle = new ICHISpotOracleUSDUniswapV3(ICHI_V2_ADDRESS, 10000);
        vm.stopBroadcast();
    }
}

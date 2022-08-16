// SPDX-License-Identifier: MIT

pragma solidity 0.8.16;

import "forge-std/Test.sol";
import {ICHISpotOracleUSDUniswapV3} from "src/contracts/ICHISpotOracleUSDUniswapV3.sol";

contract ICHISpotOracleUSDUniswapV3Test is Test {
    // the identifiers of the forks
    uint256 mainnetFork;
    uint256 public constant FORK_AT_BLOCK = 15284494;

    address constant ICHI_V2_ADDRESS = 0x111111517e4929D3dcbdfa7CCe55d30d4B6BC4d6;
    address public constant ICHI_V1_ADDRESS = 0x903bEF1736CDdf2A537176cf3C64579C3867A881;
    address public constant ONE_ICHI_ADDRESS = 0x4db2c02831c9ac305FF9311Eb661f80f1dF61e07;
    address public constant USDC_ADDRESS = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address public constant DAI_ADDRESS = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address public constant NULL_ADDRESS = address(0);

    uint256 constant MAX_INT = 2**256 - 1;
    uint256 constant MAX_SPOT_PRICE = 115792089237316195423570985008687907853269984665640564039458;

    ICHISpotOracleUSDUniswapV3 oracle;

    // create two _different_ forks during setup
    function setUp() public {
        mainnetFork = vm.createSelectFork(vm.envString("MAINNET_RPC_URL"), FORK_AT_BLOCK);
        oracle = new ICHISpotOracleUSDUniswapV3(ICHI_V2_ADDRESS, 10000);
    }

    // --------------------------------------------------------------------------
    // Test intantiation
    // --------------------------------------------------------------------------
    /**
    @notice Test an invalid address for the constructor
    */
    function tesConstructor_NullBaseToken() public {
        vm.expectRevert(bytes("Invalid baseToken"));
        new ICHISpotOracleUSDUniswapV3(address(0), 10000);
    }

    function tesConstructor_FizzPoolFee(uint24 poolFee) public {
        vm.assume(poolFee > 0);
        vm.assume(poolFee <= 10000);
        new ICHISpotOracleUSDUniswapV3(ICHI_V2_ADDRESS, poolFee);
    }

    // --------------------------------------------------------------------------
    // Test getBaseToken
    // --------------------------------------------------------------------------
    /**
    @notice Tests the oracle's getBaseToken function
    */
    function testGetBaseToken() public {
        address output = oracle.getBaseToken();
        assertEq(output, ICHI_V1_ADDRESS);
    }

    // --------------------------------------------------------------------------
    // Test getTokenDecimals
    // --------------------------------------------------------------------------
    /**
    @notice Tests the oracle's getTokenDecimals function
    */
    function testGetTokenDecimals_IchiV2() public {
        uint256 output = oracle.getTokenDecimals(ICHI_V2_ADDRESS);
        assertEq(output, 18);
    }

    /**
    @notice Tests the oracle's getTokenDecimals function
    */
    function testGetTokenDecimals_OneIchi() public {
        uint256 output = oracle.getTokenDecimals(ONE_ICHI_ADDRESS);
        assertEq(output, 18);
    }

    // --------------------------------------------------------------------------
    // Test convertSpotPrice
    // --------------------------------------------------------------------------

    /**
    @notice Tests converting the spot price to the proper output decimals
    */
    function testConvertSpotPrice(uint8 pairDecimals, uint256 spotPrice) public {
        vm.assume(spotPrice < MAX_SPOT_PRICE);
        uint256 output = oracle.convertSpotPrice(pairDecimals, spotPrice);
        assertGe(output, 0);
    }

    /**
     @notice Tests requires for converting the spot price to the proper output decimals
    */
    function testFailConvertSpotPrice() public view {
        oracle.convertSpotPrice(19, MAX_INT);
    }

    // --------------------------------------------------------------------------
    // Test getSpotPrice
    // --------------------------------------------------------------------------
    /**
    @notice Tests the oracle's getSpotPrice function with the oneICHI-ICHI pool
    */
    function testGetSpotPrice_OneIchiIchi() public {
        uint256 output = oracle.getSpotPrice(ONE_ICHI_ADDRESS);
        assertEq(output, 5341017781430727926);
    }

    /**
    @notice Tests the oracle's getSpotPrice function with the USDC-ICHI pool
    */
    function testGetSpotPrice_UsdcIchi() public {
        uint256 output = oracle.getSpotPrice(USDC_ADDRESS);
        assertEq(output, 5326631000000000000);
    }

    /**
    @notice Tests the oracle's getSpotPrice function with a pool that doesn't exit, which should fail
    */
    function testGetSpotPrice_Null_Reverts() public {
        vm.expectRevert(bytes("ICHISpotOracleUSDUniswapV3: unknown pool"));
        oracle.getSpotPrice(NULL_ADDRESS);
    }

    // --------------------------------------------------------------------------
    // Test getICHIPrice
    // --------------------------------------------------------------------------
    /**
    @notice Tests the oracle's getICHIPrice function for oneICHI/ICHI pool
    */
    function testGetICHIPrice_OneIchi() public {
        uint256 output = oracle.getICHIPrice(ONE_ICHI_ADDRESS, NULL_ADDRESS);
        // Note: We know this exact price at the block we are forking for the test
        assertEq(output, 5341017781430727926);
    }

    /**
    @notice Tests the oracle's getICHIPrice function for USDC/ICHI pool
    */
    function testGetICHIPrice_Usdc() public {
        uint256 output = oracle.getICHIPrice(USDC_ADDRESS, NULL_ADDRESS);
        // Note: We know this exact price at the block we are forking for the test
        assertEq(output, 5326631000000000000);
    }

    /**
    @notice Tests that the oracle's getICHIPrice fails for an unknown pool
    */
    function testGetICHIPrice_Null_Reverts() public {
        vm.expectRevert(bytes("ICHISpotOracleUSDUniswapV3: chainlink_ price calculation not yet implemented"));
        oracle.getICHIPrice(NULL_ADDRESS, NULL_ADDRESS);
    }

    function testGetICHIPrice_Dai_Reverts() public {
        vm.expectRevert(bytes("ICHISpotOracleUSDUniswapV3: unknown pool"));
        oracle.getICHIPrice(DAI_ADDRESS, NULL_ADDRESS);
    }
}

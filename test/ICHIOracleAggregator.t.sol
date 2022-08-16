// SPDX-License-Identifier: MIT

pragma solidity 0.8.16;

import "forge-std/Test.sol";
import {ICHISpotOracleUSDUniswapV3} from "src/contracts/ICHISpotOracleUSDUniswapV3.sol";
import {ICHIOracleAggregator} from "util-contracts/oracles/ICHIOracleAggregator.sol";
import {IBaseOracle} from "util-contracts/interfaces/IBaseOracle.sol";
import {IOneTokenV1} from "lib/ichi-oneToken/contracts/interface/IOneTokenV1.sol";
import {ERC20} from "openzeppelin-contracts/token/ERC20/ERC20.sol";
import {IUniswapV3Factory} from "lib/v3-core/contracts/interfaces/IUniswapV3Factory.sol";
import {UniswapV3Pool} from "lib/v3-core/contracts/UniswapV3Pool.sol";
import {ISwapRouter} from "lib/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import {SwapRouter} from "lib/v3-periphery/contracts/SwapRouter.sol";
import {INonfungiblePositionManager} from "lib/v3-periphery/contracts/interfaces/INonfungiblePositionManager.sol";

// Ref: https://book.getfoundry.sh/cheatcodes/get-code
contract ICHIOracleAggregatorTest is Test {
    // the identifiers of the forks
    uint256 mainnetFork;
    uint24 public constant FORK_AT_BLOCK = 15284494;

    address constant ICHI_V2_ADDRESS = 0x111111517e4929D3dcbdfa7CCe55d30d4B6BC4d6;
    address public constant ICHI_V1_ADDRESS = 0x903bEF1736CDdf2A537176cf3C64579C3867A881;
    address public constant ONE_ICHI_ADDRESS = 0x4db2c02831c9ac305FF9311Eb661f80f1dF61e07;
    address public constant USDC_ADDRESS = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address public constant DAI_ADDRESS = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address public constant NULL_ADDRESS = address(0);
    address public constant SUSHISWAP_ICHI_LP_TOKEN_ADDRESS = 0x9cD028B1287803250B1e226F0180EB725428d069;
    address public constant ETH_USD_CHAINLINK_ADDRESS = 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419;

    address public constant ICHI_ORACLE_AGGREGATOR_ADDRESS = 0xD41EA28e17BD06136c416cA942fB997122138139;
    address public constant ICHI_ORACLE_AGGREGATOR_OWNER_ADDRESS = 0xfF7B5E167c9877f2b9f65D19d9c8c9aa651Fe19F;
    address public constant FIRST_ORACLE_ADDRESS = 0x1f8340Aef6B33d12C89e901DDe312467c2F146E2;
    address public constant UNI_V3_FACTORY_ADDRESS = 0x1F98431c8aD98523631AE4a59f267346ea31F984;
    address public constant UNI_V3_NFT_POSITION_MANAGER = 0xC36442b4a4522E871399CD717aBDD847Ab11FE88;
    address payable public constant UNI_V3_ROUTER = 0xE592427A0AEce92De3Edee1F18E0157C05861564;

    address public alice;
    address public constant ACCOUNT_WITH_ICHI_ADDRESS = 0xE63AEf9fDE206a4D290E7079a1223F26d3ECA545;
    address public constant CIRCLE_ACCOUNT_ADDRESS = 0x55FE002aefF02F77364de339a1292923A15844B8;

    ICHIOracleAggregator aggregator;
    ICHISpotOracleUSDUniswapV3 newOracle;
    IOneTokenV1 oneIchi;
    IUniswapV3Factory uniV3Factory;
    address oneIchiIchiPoolAddress;
    UniswapV3Pool oneIchiIchiPool;
    // NonfungiblePositionManager npm;
    INonfungiblePositionManager npm;
    SwapRouter router;

    function setUp() public {
        alice = vm.addr(1);
        mainnetFork = vm.createSelectFork(
            vm.envString("MAINNET_RPC_URL"),
            15284494
        );
        // vm.startPrank(ALICE);

        aggregator = ICHIOracleAggregator(ICHI_ORACLE_AGGREGATOR_ADDRESS);
        newOracle = new ICHISpotOracleUSDUniswapV3(ICHI_V2_ADDRESS, 10000);
        uniV3Factory = IUniswapV3Factory(UNI_V3_FACTORY_ADDRESS);
        oneIchiIchiPoolAddress = uniV3Factory.getPool(
            ICHI_V2_ADDRESS,
            ONE_ICHI_ADDRESS,
            10000
        );
        oneIchiIchiPool = UniswapV3Pool(oneIchiIchiPoolAddress);
        console.log("oneICHI/ICHI pool address", oneIchiIchiPoolAddress);
        // npm = NonfungiblePositionManager(UNI_V3_NFT_POSITION_MANAGER);
        npm = INonfungiblePositionManager(UNI_V3_NFT_POSITION_MANAGER);
        router = SwapRouter(UNI_V3_ROUTER);

        // Original setOracles
        // 0	token	address	0x903bEF1736CDdf2A537176cf3C64579C3867A881
        // 1	maxPriceDeviation	uint256	500
        // 2	oracles_	address[]	0x1f8340Aef6B33d12C89e901DDe312467c2F146E2
        // 0xE0191c950B2c19D7A470B00c59969c17fCD9a150
        // 3	pairs_	address[]	0x9cD028B1287803250B1e226F0180EB725428d069
        // 0x4a2F0Ca5E03B2cF81AebD936328CF2085037b63B
        // 4	chainlinks_	address[]	0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419
        // 0x1E6cF0D433de4FE882A437ABC654F58E1e78548c

        // Define new oracles_ addresses
        IBaseOracle[] memory new_oracles = new IBaseOracle[](2);
        new_oracles[0] = IBaseOracle(FIRST_ORACLE_ADDRESS);
        // Old oracle address: 0xE0191c950B2c19D7A470B00c59969c17fCD9a150
        new_oracles[1] = IBaseOracle(address(newOracle));

        // Define new pairs_ addresses
        address[] memory new_pairs = new address[](2);
        new_pairs[0] = SUSHISWAP_ICHI_LP_TOKEN_ADDRESS;
        new_pairs[1] = ONE_ICHI_ADDRESS;

        // Define new chainlink addresses
        // Remember since we are using one_ichi then the chainlink_ parameter in the new oracle won't take a chainlink address, so just pass null address
        address[] memory new_chainlinks = new address[](2);
        new_chainlinks[0] = ETH_USD_CHAINLINK_ADDRESS;
        new_chainlinks[1] = NULL_ADDRESS;

        // Assume the Oracle's owner account
        vm.prank(ICHI_ORACLE_AGGREGATOR_OWNER_ADDRESS);

        aggregator.setOracles(
            ICHI_V1_ADDRESS,
            500,
            new_oracles,
            new_pairs,
            new_chainlinks
        );

        oneIchi = IOneTokenV1(ONE_ICHI_ADDRESS);
    }

    // --------------------------------------------------------------------------
    // Test ICHIPrice
    // --------------------------------------------------------------------------
    /**
    @notice Tests the aggregator oracle's getICHIPrice function
    */
    function testICHIPrice() public {
        uint256 output = aggregator.ICHIPrice();
        console.log("aggregator ICHIPrice", output);
        assertGt(output, 0);
    }

    // --------------------------------------------------------------------------
    // Mint oneICHI
    // --------------------------------------------------------------------------
    function mintOneIchi(uint32 oneIchiAmount) public {
        uint256 oneIchiAmountBN = oneIchiAmount * 10**18;

        // Impersonates account until stopPrank is called
        vm.startPrank(CIRCLE_ACCOUNT_ADDRESS);

        ERC20(USDC_ADDRESS).approve(ONE_ICHI_ADDRESS, 2**256 - 1);

        oneIchi.mint(USDC_ADDRESS, oneIchiAmountBN);

        // Stop impersonating circle account
        vm.stopPrank();
    }

    // --------------------------------------------------------------------------
    // Put ICHI above price in the oneICHI-ICHI pool
    // --------------------------------------------------------------------------
    /**
    @notice Put ICHI above the price in the oneICHI-ICHI pool so there is enough to
    * swap for later
    */
    function addIchiAbovePrice() public {
        vm.startPrank(ACCOUNT_WITH_ICHI_ADDRESS);
        // uint256 initialPrice = aggregator.ICHIPrice();
        console.log(
            "ichiv2 Balance of large account",
            ERC20(ICHI_V2_ADDRESS).balanceOf(ACCOUNT_WITH_ICHI_ADDRESS)
        );

        int24 tickSpacing = oneIchiIchiPool.tickSpacing();

        (, int24 tick, , , , , ) = oneIchiIchiPool.slot0();

        int24 tickLower = (int24(tick / tickSpacing) * tickSpacing) + tickSpacing;
        int24 tickUpper = tickLower * 2 + tickSpacing**2;

        // Example Mint tx: https://etherscan.io/tx/0x7fc473f597594065cdbc9d6f9abf598ce3d203a051b57d7177cb78827001d474
        INonfungiblePositionManager.MintParams
            memory params = INonfungiblePositionManager.MintParams({
                token0: ICHI_V2_ADDRESS,
                token1: ONE_ICHI_ADDRESS,
                fee: 10000,
                tickLower: tickLower,
                tickUpper: tickUpper,
                // amount0Desired is the amout we are putting into the position
                amount0Desired: 1000 * 10**18,
                amount1Desired: 0,
                // May or may not be amount, because way it does liquidity on curve
                // May not be able to to put that amount of liquidity between ticks.
                // It may be able to put all be a little there.  Amount want to put in * .95 or something.
                amount0Min: (900 * 10**18),
                amount1Min: 0,
                recipient: ACCOUNT_WITH_ICHI_ADDRESS,
                deadline: 2000000000
            });

        // Approve UniV3 to spend ICHI on behalf of the user
        ERC20(ICHI_V2_ADDRESS).approve(UNI_V3_NFT_POSITION_MANAGER, 2**256 - 1);

        npm.mint(params);

        vm.stopPrank();
    }

    // --------------------------------------------------------------------------
    // Move price
    // --------------------------------------------------------------------------
    /**
    @notice Move ichi price slightly and avoid a deviation
    */
    function testMoveIchiPriceBeyondDeviation() public {
        // Give the Circle account 1 million oneICHI to play with
        deal(ONE_ICHI_ADDRESS, CIRCLE_ACCOUNT_ADDRESS, 1000000 * 10**18);

        // Now add some ichi above the price
        addIchiAbovePrice();

        console.log(
            "oneICHI Balance of large account",
            ERC20(ONE_ICHI_ADDRESS).balanceOf(CIRCLE_ACCOUNT_ADDRESS)
        );
        vm.startPrank(CIRCLE_ACCOUNT_ADDRESS);

        uint256 oneIchiIn = 12;
        uint256 oneIchiInBn = oneIchiIn * 10**18;

        uint256 ichiOut = 2;
        uint256 ichiOutBn = ichiOut * 10**18;

        ISwapRouter.ExactOutputSingleParams memory params = ISwapRouter.ExactOutputSingleParams({
            tokenIn: ONE_ICHI_ADDRESS,
            tokenOut: ICHI_V2_ADDRESS,
            fee: 10000,
            recipient: CIRCLE_ACCOUNT_ADDRESS,
            deadline: block.timestamp + (60 * 60 * 2),
            amountOut: ichiOutBn,
            amountInMaximum: oneIchiInBn,
            sqrtPriceLimitX96: 0
          });

        // Approve the Router to use the oneICHI
        ERC20(ONE_ICHI_ADDRESS).approve(UNI_V3_ROUTER, 2**256 - 1);

        console.log(
            "ICHI balance before swap",
            ERC20(ICHI_V2_ADDRESS).balanceOf(CIRCLE_ACCOUNT_ADDRESS)
        );

        uint256 ichiPriceBefore = aggregator.ICHIPrice();
        console.log(
            "ICHI Aggregator Oracle price before swap",
            ichiPriceBefore
        );

        // Execute the swap
        router.exactOutputSingle(params);

        console.log(
            "ICHI balance after swap",
            ERC20(ICHI_V2_ADDRESS).balanceOf(CIRCLE_ACCOUNT_ADDRESS)
        );
        uint256 ichiPriceAfter = aggregator.ICHIPrice();
        console.log(
            "ICHI Aggregator Oracle price after swap",
            ichiPriceAfter
        );

        uint256 priceDelta = stdMath.delta(ichiPriceBefore, ichiPriceAfter);
        console.log(
            "ICHI Aggregator Oracle price delta before/after",
            priceDelta
        );

        vm.stopPrank();
    }

    /**
    @notice Attempt to move the ichi price to cause a deviation in the aggregator oracle
    */
    function testFailMoveIchiPriceBeyondDeviation() public {
        // For some reason this isn't working as expected
        // vm.expectRevert(bytes("too much deviation (2 valid sources)"));

        // mintOneIchi(1_000_000);

        // Give the Circle account 1 million oneICHI to play with
        deal(ONE_ICHI_ADDRESS, CIRCLE_ACCOUNT_ADDRESS, 1000000 * 10**18);

        // Now add some ichi above the price
        addIchiAbovePrice();

        console.log(
            "oneICHI Balance of large account",
            ERC20(ONE_ICHI_ADDRESS).balanceOf(CIRCLE_ACCOUNT_ADDRESS)
        );
        vm.startPrank(CIRCLE_ACCOUNT_ADDRESS);

        uint256 oneIchiIn = 1000000;
        uint256 oneIchiInBn = oneIchiIn * 10**18;

        uint256 ichiOut = 50000;
        uint256 ichiOutBn = ichiOut * 10**18;

        ISwapRouter.ExactOutputSingleParams memory params = ISwapRouter.ExactOutputSingleParams({
            tokenIn: ONE_ICHI_ADDRESS,
            tokenOut: ICHI_V2_ADDRESS,
            fee: 10000,
            recipient: CIRCLE_ACCOUNT_ADDRESS,
            deadline: block.timestamp + (60 * 60 * 2),
            amountOut: ichiOutBn,
            amountInMaximum: oneIchiInBn,
            sqrtPriceLimitX96: 0
          });

        // Approve the Router to use the oneICHI
        ERC20(ONE_ICHI_ADDRESS).approve(UNI_V3_ROUTER, 2**256 - 1);

        console.log(
            "ICHI balance before swap",
            ERC20(ICHI_V2_ADDRESS).balanceOf(CIRCLE_ACCOUNT_ADDRESS)
        );

        uint256 ichiPriceBefore = aggregator.ICHIPrice();
        console.log(
            "ICHI Aggregator Oracle price before swap",
            ichiPriceBefore
        );

        // Execute the swap
        router.exactOutputSingle(params);

        console.log(
            "ICHI balance after swap",
            ERC20(ICHI_V2_ADDRESS).balanceOf(CIRCLE_ACCOUNT_ADDRESS)
        );
        uint256 ichiPriceAfter = aggregator.ICHIPrice();
        console.log(
            "ICHI Aggregator Oracle price after swap",
            ichiPriceAfter
        );

        vm.stopPrank();
    }
}

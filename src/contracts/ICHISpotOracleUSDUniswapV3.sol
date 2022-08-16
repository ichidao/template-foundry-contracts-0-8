// SPDX-License-Identifier: MIT

pragma solidity 0.8.16;

// Note the default import for contracts is src, but there is no src in OpenZepplin, just contracts, so go up a dir
import {SafeMath} from "openzeppelin-contracts/math/SafeMath.sol";
import {ERC20} from "openzeppelin-contracts/token/ERC20/ERC20.sol";
import {OracleLibrary} from "v3-periphery/libraries/OracleLibrary.sol";
import {IUniswapV3Factory} from "v3-core/contracts/interfaces/IUniswapV3Factory.sol";
import {IUniswapV3Pool} from "v3-core/contracts/interfaces/IUniswapV3Pool.sol";
import {UsingBaseOracle} from "./UsingBaseOracle.sol";

/*
 * @notice ICHISpotOracleUSDUniswapV3 returns the price of ICHI in terms of USD
 */
contract ICHISpotOracleUSDUniswapV3 is UsingBaseOracle {
    using SafeMath for uint256;
    address public constant ICHI_LEGACY_TOKEN_ADDRESS = 0x903bEF1736CDdf2A537176cf3C64579C3867A881;
    address public baseToken;
    uint128 dollarInBaseTokenDecimals;
    uint8 public baseTokenDecimals;
    uint24 public poolFee;

    address constant NULL_ADDRESS = address(0);
    address constant UNI_V3_FACTORY = 0x1F98431c8aD98523631AE4a59f267346ea31F984;
    uint256 constant OUTPUT_DECIMALS = 18;
    // Max spot price when converting the spot price to the proper output given pairDecimals
    uint256 constant MAX_SPOT_PRICE = 115792089237316195423570985008687907853269984665640564039458;

    constructor(address _baseToken, uint24 _poolFee) {
        require(_baseToken != NULL_ADDRESS, "Invalid baseToken");
        require(_poolFee > 0 && poolFee < 10000, "Invalid poolFee");

        baseToken = _baseToken;
        baseTokenDecimals = ERC20(baseToken).decimals();
        poolFee = _poolFee;
        // Convert the $1 dollar into the decimals of the pool
        dollarInBaseTokenDecimals = 1 * uint128(10**baseTokenDecimals);
    }

    /**
    @notice By default return the ICHI price in terms of USD (9 decimals) for the given pool.  Also by default assumes $1 since with oneICHI-ICHI, oneICHI is worth $1
    @param pair_ the pair address to lookup the pool to get a ICHI price quote for
    @param price the price at the current tick in the pool based on the quoteToken
    */
    function getICHIPrice(address pair_, address chainlink_) external view override returns (uint256 price) {
        // Lookup pools such as oneICHI-ICHI and UDSC-ICHI.  Treat the pair_ as one of the pairs and assume the others is ICHI for now.
        if (pair_ != NULL_ADDRESS) {
            return getSpotPrice(pair_);
        }

        require(chainlink_ != NULL_ADDRESS, "ICHISpotOracleUSDUniswapV3: chainlink_ price calculation not yet implemented");

        // FUTURE: If Chainlink Null assume 1 dollar, otherwise use chainlink to lookup price , so like with usdc ichi, we know ichi s worth 4.9 USDC.  ICHI worth 4.9 USDC, but if we don't know how many
        // dopllars USDC work, do a chainlink lookup, say 2 dollars, then do 4.9 * 2.  So if pairs are not dollars, like with the HODL vaults, then need to know the value in dollars
        // like 1 ichi worth 17 cell tokens.
    }

    /**
    @notice checks whether the pool is unlocked and returns the current tick
    @param pool the address of the pool
    @param output current tick of the given pool
    */
    function poolTick(address pool) internal view returns (int24 output) {
        IUniswapV3Pool oracle = IUniswapV3Pool(pool);
        (, int24 tick, , , , , bool unlocked_) = oracle.slot0();
        require(unlocked_, "ICHISpotOracleUSDUniswapV3: the pool is locked");
        // Verify this equates to return, it seems to
        output = tick;
    }

    /**
     * @notice utility function that checks whether there is an existing pool for the specified tokens. Returns true if the pool exists
     * @param token0 address of the first token
     * @param token1 address of the second token
     * @return output true if pool exists otherwise false
     */
    function poolExists(address token0, address token1) private view returns (bool output) {
        IUniswapV3Factory factory = IUniswapV3Factory(UNI_V3_FACTORY);
        output = factory.getPool(token0, token1, poolFee) != NULL_ADDRESS;
    }

    /**
     * @notice converts the given spot price to the 9 decimal output
     * @param pairDecimals decimals of the pair token
     * @param spotPrice spot price to convert to the output decimals
     * @return output spot price denominated in 9 decimals
     */
    function convertSpotPrice(uint8 pairDecimals, uint256 spotPrice) public pure returns (uint256 output) {
        // When pair decimals is < OUTPUT_DECIMALS ensure the multiplication doesn't overflow
        // with a large spot price
        require(spotPrice < MAX_SPOT_PRICE, "ICHISpotOracleUSDUniswapV3: Spot price too large to convert");

        if (pairDecimals >= OUTPUT_DECIMALS) {
            output = spotPrice.div(10**(pairDecimals - OUTPUT_DECIMALS));
        } else {
            output = spotPrice.mul(10**(OUTPUT_DECIMALS - pairDecimals));
        }
    }

    /**
     * @notice gets the spot price of ICHI denominated in 9 decimals
     * @param quoteToken address of the first token
     * @return output spot price denominated in 9 decimals
     */
    function getSpotPrice(address quoteToken) public view returns (uint256 output) {
        // check if there is a pool for the second pair
        require(poolExists(quoteToken, baseToken), "ICHISpotOracleUSDUniswapV3: unknown pool");

        IUniswapV3Factory factory = IUniswapV3Factory(UNI_V3_FACTORY);
        address pool = factory.getPool(quoteToken, baseToken, poolFee);

        int24 tick = poolTick(pool);

        // Get the decimals from the pair token
        uint8 pairDecimals = getTokenDecimals(quoteToken);

        // Get Spot price
        uint256 spotPrice = OracleLibrary.getQuoteAtTick(tick, dollarInBaseTokenDecimals, baseToken, quoteToken);

        output = convertSpotPrice(pairDecimals, spotPrice);
    }

    /**
     * @notice get the base token for the pool
     * @return output base token
     */
    function getBaseToken() external pure override returns (address output) {
        output = ICHI_LEGACY_TOKEN_ADDRESS;
    }

    /**
     * @notice get the decimals for this pool
     * @return output token decimals
     */
    function decimals() external view override returns (uint256 output) {
        output = baseTokenDecimals;
    }

    /**
     * @notice utility function to get the decimals given a token address
     * @param tokenAddress address of the ERC20 token
     * @return output token decimals
     */
    function getTokenDecimals(address tokenAddress) public view returns (uint8 output) {
        ERC20 pairToken = ERC20(tokenAddress);
        output = pairToken.decimals();
    }
}

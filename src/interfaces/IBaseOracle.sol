// SPDX-License-Identifier: MIT

pragma solidity 0.8.16;

interface IBaseOracle {
    function getICHIPrice(address pair_, address chainlink_)
        external
        view
        returns (uint256);

    function getBaseToken() external view returns (address);

    function decimals() external view returns (uint256);
}

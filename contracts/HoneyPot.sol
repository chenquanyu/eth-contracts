// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract HoneyPot is Ownable {
    using SafeMath for uint256;

    struct Call {
        address router;
        uint256 buyAmount0; // pay amount
        uint256 buyAmount1; // get min amount, default 0
        uint256 sellAmount0;
        uint256 sellAmount1;
        uint256 sellPercent;
        address[] buyPath;
        address[] sellPath;
        // ETH swap
        // sig = [
        //   'getAmountsOut(uint256,address[])',
        //   'swapExactETHForTokensSupportingFeeOnTransferTokens(uint256,address[],address,uint256)',
        //   'swapExactTokensForETHSupportingFeeOnTransferTokens(uint256,uint256,address[],address,uint256)',
        // ]
        // token swap
        // sig = [
        //   'getAmountsOut(uint256,address[])',
        //   'swapExactTokensForTokensSupportingFeeOnTransferTokens(uint256,uint256,address[],address,uint256)',
        //   'swapExactTokensForTokensSupportingFeeOnTransferTokens(uint256,uint256,address[],address,uint256)',
        // ]
        string[] sig;
        bool etherIn;
    }

    struct Pot {
        uint256 buyExpectedOut;
        uint256 buyActualOut;
        uint256 sellExpectedOut;
        uint256 sellActualOut;
        uint256 buyGasUsed;
        uint256 approveGasUsed;
        uint256 sellGasUsed;
        bytes bytesError;
        bytes secondSellError;
        uint256 state; // 0 success, 1 buy getAmountsOut error, 2 buy swap error, 3 sell getAmountsOut error, 4 sell swap error, 5 sellPercent getAmountsOut error, 6 sellPercent swap error
    }

    event Received(address, uint);
    receive() external payable {
        emit Received(msg.sender, msg.value);
    }

    fallback() external payable {}

    function callOptionalReturn(
        address _contract,
        uint256 _value,
        bytes memory data
    ) internal returns (bool success, bytes memory returnData) {
        if (_value == 0) {
            (success, returnData) = _contract.call(data);
        } else {
            (success, returnData) = _contract.call{value: _value}(data);
        }
    }

    function getAmountsOut(
        address router,
        string memory sig,
        uint256 amount,
        address[] memory path
    ) internal returns (bool success, bytes memory returnData) {
        (success, returnData) = callOptionalReturn(
            router,
            0,
            abi.encodeWithSignature(sig, amount, path)
        );
    }

    function swap(
        address router,
        string memory sig,
        bool etherIn,
        uint256 amount0,
        uint256 amount1,
        address[] memory path,
        address to,
        uint256 deadline
    ) internal returns (bool success, bytes memory returnData) {
        if (etherIn) {
            (success, returnData) = callOptionalReturn(
                router,
                amount0,
                abi.encodeWithSignature(sig, amount1, path, to, deadline)
            );
        } else {
            (success, returnData) = callOptionalReturn(
                router,
                0,
                abi.encodeWithSignature(
                    sig,
                    amount0,
                    amount1,
                    path,
                    to,
                    deadline
                )
            );
        }
    }

    function isHoneyPot(Call memory call) onlyOwner
        external 
        payable
        returns (Pot memory pot)  
    {
        uint256[] memory amounts;
        (bool success, bytes memory data) = getAmountsOut(
            call.router,
            call.sig[0],
            call.buyAmount0,
            call.buyPath
        );
        if (success) {
            amounts = abi.decode(data, (uint256[]));
            pot.buyExpectedOut = amounts[amounts.length - 1];
        } else {
            pot.bytesError = data;
            pot.state = 1;
            return pot;
        }
        if (!call.etherIn) {
            IERC20(call.buyPath[0]).approve(call.router, type(uint256).max);
        }
        uint256 gasUsed = gasleft();
        uint256 beforeAmount = IERC20(call.buyPath[call.buyPath.length - 1])
                .balanceOf(address(this));
        (success, data) = swap(
            call.router,
            call.sig[1],
            call.etherIn,
            call.buyAmount0,
            call.buyAmount1,
            call.buyPath,
            address(this),
            block.timestamp
        );
        pot.buyGasUsed = gasUsed.sub(gasleft());
        if (success) {
            pot.buyActualOut = IERC20(call.buyPath[call.buyPath.length - 1])
                .balanceOf(address(this)) - beforeAmount;
        } else {
            pot.bytesError = data;
            pot.state = 2;
            return pot;
        }

        uint256 sellAmount = call.sellAmount0 == 0
            ? pot.buyActualOut
            : call.sellAmount0;
        (success, data) = getAmountsOut(
            call.router,
            call.sig[0],
            sellAmount,
            call.sellPath
        );
        if (success) {
            amounts = abi.decode(data, (uint256[]));
            pot.sellExpectedOut = amounts[amounts.length - 1];
        } else {
            pot.bytesError = data;
            pot.state = 3;
            return pot;
        }

        gasUsed = gasleft();
        IERC20(call.sellPath[0]).approve(call.router, type(uint256).max);
        pot.approveGasUsed = gasUsed.sub(gasleft());

        gasUsed = gasleft();
        uint256 beforeBalance = address(this).balance;
        beforeAmount = IERC20(call.sellPath[call.sellPath.length - 1]).balanceOf(address(this));
        (success, data) = swap(
            call.router,
            call.sig[2],
            false,
            sellAmount,
            call.sellAmount1,
            call.sellPath,
            address(this),
            block.timestamp
        );
        pot.sellGasUsed = gasUsed.sub(gasleft());
        if (success) {
            if (call.etherIn) {
                pot.sellActualOut = address(this).balance - beforeBalance;
            } else {
                pot.sellActualOut = IERC20(
                    call.sellPath[call.sellPath.length - 1]
                ).balanceOf(address(this)) - beforeAmount;
            }
            return pot;
        } else {
            pot.bytesError = data;
            pot.state = 4;
        }
        if (call.sellPercent != 0) {
            sellAmount = sellAmount.mul(call.sellPercent).div(10000);
        }
        (success, data) = getAmountsOut(
            call.router,
            call.sig[0],
            sellAmount,
            call.sellPath
        );
        if (success) {
            amounts = abi.decode(data, (uint256[]));
            pot.sellExpectedOut = amounts[amounts.length - 1];
        } else {
            pot.bytesError = data;
            pot.state = 5;
            return pot;
        }
        beforeBalance = address(this).balance;
        beforeAmount = IERC20(call.sellPath[call.sellPath.length - 1]).balanceOf(address(this));
        gasUsed = gasleft();
        (success, data) = swap(
            call.router,
            call.sig[2],
            false,
            sellAmount,
            call.sellAmount1,
            call.sellPath,
            address(this),
            block.timestamp
        );
        pot.sellGasUsed = gasUsed.sub(gasleft());
        if (success) {
            if (call.etherIn) {
                pot.sellActualOut = address(this).balance - beforeBalance;
            } else {
                pot.sellActualOut = IERC20(call.sellPath[call.sellPath.length - 1]).balanceOf(address(this)) - beforeAmount;
            }
            return pot;
        } else {
            pot.secondSellError = data;
            pot.state = 6;
            return pot;
        }
    }

    function inCaseTokensGetStuck(
        address payable recipient,
        address token,
        uint256 amount
    ) external onlyOwner {
        // require(msg.sender == , "!authorized");
        if (token == address(0)) {
            recipient.transfer(amount);
        } else {
            IERC20(token).transfer(recipient, amount);
        }
    }
}

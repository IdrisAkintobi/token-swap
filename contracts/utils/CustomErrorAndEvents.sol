// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

abstract contract CustomErrorAndEvents {
    // Custom Errors
    error OfferAmountMustBeGreaterThanZero();
    error WantAmountMustBeGreaterThanZero();
    error InsufficientAllowance(
        address token,
        address spender,
        uint256 required
    );
    error InsufficientBalance(address token, address owner, uint256 required);
    error OrderDoesNotExist(uint256 orderId);
    error OrderNotApproved(uint256 orderId);
    error OrderAlreadyFulfilled(uint256 orderId);
    error OrderCanceledError(uint256 orderId);
    error OnlyCreatorCanCancel(address caller);
    error OnlyOwnerCanPerformThisAction();
    error TransferFailed(address token);
    error AddressZeroDetected();
    error CanNotSwapSameToken();

    // Events
    event OrderCreated(
        uint256 indexed id,
        address indexed creator,
        address offerToken,
        uint256 offerAmount,
        address wantToken,
        uint256 wantAmount
    );
    event OrderFulfilled(
        uint256 indexed id,
        address indexed fulfiller,
        address offerToken,
        uint256 offerAmount,
        address wantToken,
        uint256 wantAmount
    );
    event OrderCanceled(uint256 indexed id, address indexed creator);
    event OrderApproved(uint256 indexed id, address indexed owner);
    event OrderDeclined(uint256 indexed id, address indexed owner);
}

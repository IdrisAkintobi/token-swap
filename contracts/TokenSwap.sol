// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "./utils/CustomErrorAndEvents.sol";

contract TokenSwap is CustomErrorAndEvents {
    address private owner;
    struct Order {
        uint256 id;
        address creator;
        address offerToken;
        uint256 offerAmount;
        address wantToken;
        uint256 wantAmount;
        bool fulfilled;
        bool canceled;
        bool approved;
    }

    uint256 public orderCount;
    mapping(uint256 => Order) public orders;

    constructor() {
        owner = msg.sender;
    }

    // Modifiers
    modifier onlyOwner() {
        if (msg.sender != owner) revert OnlyOwnerCanPerformThisAction();
        _;
    }

    modifier onlyApproved(uint256 orderId) {
        if (!orders[orderId].approved) revert OrderNotApproved(orderId);
        _;
    }

    function createOrder(
        address offerToken,
        uint256 offerAmount,
        address wantToken,
        uint256 wantAmount
    ) external {
        if (offerToken == address(0) || wantToken == address(0))
            revert AddressZeroDetected();
        if (offerToken == wantToken) revert CanNotSwapSameToken();
        if (offerAmount == 0) revert OfferAmountMustBeGreaterThanZero();
        if (wantAmount == 0) revert WantAmountMustBeGreaterThanZero();
        if (
            IERC20(offerToken).allowance(msg.sender, address(this)) <
            offerAmount
        ) {
            revert InsufficientAllowance(
                offerToken,
                address(this),
                offerAmount
            );
        }
        if (IERC20(offerToken).balanceOf(msg.sender) < offerAmount) {
            revert InsufficientBalance(offerToken, msg.sender, offerAmount);
        }

        // Transfer the offer tokens to the contract
        bool sent = IERC20(offerToken).transferFrom(
            msg.sender,
            address(this),
            offerAmount
        );
        if (!sent) revert TransferFailed(offerToken);

        orderCount += 1;
        orders[orderCount] = Order({
            id: orderCount,
            creator: msg.sender,
            offerToken: offerToken,
            offerAmount: offerAmount,
            wantToken: wantToken,
            wantAmount: wantAmount,
            fulfilled: false,
            canceled: false,
            approved: false
        });

        emit OrderCreated(
            orderCount,
            msg.sender,
            offerToken,
            offerAmount,
            wantToken,
            wantAmount
        );
    }

    function approveOrder(uint256 orderId) external onlyOwner {
        Order storage order = orders[orderId];
        if (order.id != orderId) revert OrderDoesNotExist(orderId);
        if (order.approved) revert OrderAlreadyFulfilled(orderId);
        order.approved = true;
        emit OrderApproved(orderId, msg.sender);
    }

    function declineOrder(uint256 orderId) external onlyOwner {
        Order storage order = orders[orderId];
        if (order.id != orderId) revert OrderDoesNotExist(orderId);
        if (order.canceled) revert OrderCanceledError(orderId);
        order.canceled = true;
        emit OrderDeclined(orderId, msg.sender);
    }

    function fulfillOrder(
        uint256 orderId,
        uint256 gasAmount
    ) external onlyApproved(orderId) {
        Order storage order = orders[orderId];
        if (order.id != orderId) revert OrderDoesNotExist(orderId);
        if (order.fulfilled) revert OrderAlreadyFulfilled(orderId);
        if (order.canceled) revert OrderCanceledError(orderId);
        if (
            IERC20(order.wantToken).allowance(msg.sender, address(this)) <
            order.wantAmount
        ) {
            revert InsufficientAllowance(
                order.wantToken,
                address(this),
                order.wantAmount
            );
        }
        if (IERC20(order.wantToken).balanceOf(msg.sender) < order.wantAmount) {
            revert InsufficientBalance(
                order.wantToken,
                msg.sender,
                order.wantAmount
            );
        }

        // 1. Update the order as fulfilled before transfer (reentrancy prevention)
        order.fulfilled = true;

        // 2. Transfer the desired tokens from the fulfiller to the creator
        (bool received, ) = order.wantToken.call{gas: gasAmount}(
            abi.encodeWithSignature(
                "transferFrom(address,address,uint256)",
                msg.sender,
                order.creator,
                order.wantAmount
            )
        );
        if (!received) revert TransferFailed(order.wantToken);

        // 3. Transfer the offer tokens from the contract to the fulfiller
        (bool sent, ) = order.offerToken.call{gas: gasAmount}(
            abi.encodeWithSignature(
                "transfer(address,uint256)",
                msg.sender,
                order.offerAmount
            )
        );
        if (!sent) revert TransferFailed(order.offerToken);

        emit OrderFulfilled(
            orderId,
            msg.sender,
            order.offerToken,
            order.offerAmount,
            order.wantToken,
            order.wantAmount
        );
    }

    function cancelOrder(uint256 orderId) external {
        Order storage order = orders[orderId];
        if (order.creator != msg.sender)
            revert OnlyCreatorCanCancel(msg.sender);
        if (order.fulfilled) revert OrderAlreadyFulfilled(orderId);
        if (order.canceled) revert OrderCanceledError(orderId);

        order.canceled = true;

        // Return the offer tokens to the creator
        (bool returned, ) = order.offerToken.call(
            abi.encodeWithSignature(
                "transfer(address,uint256)",
                msg.sender,
                order.offerAmount
            )
        );
        if (!returned) revert TransferFailed(order.offerToken);

        emit OrderCanceled(orderId, msg.sender);
    }

    function getOrder(uint256 orderId) external view returns (Order memory) {
        return orders[orderId];
    }
}

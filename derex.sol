// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

contract DerivativesExchange {
    enum OrderType { Bid, Ask }
    enum OrderStatus { Open, Filled }

    struct Order {
        address trader;
        OrderType orderType;
        uint256 price;
        uint256 size;
        OrderStatus status;
    }

    mapping(bytes32 => Order) public orders;

    event NewOrder(bytes32 indexed orderId, address indexed trader, OrderType orderType, uint256 price, uint256 size);
    event OrderFilled(bytes32 indexed orderId, address indexed trader, uint256 filled);

    function placeOrder(OrderType orderType, uint256 price, uint256 size) public {
        require(size > 0, "Size must be greater than 0");

        bytes32 orderId = keccak256(abi.encodePacked(orderType, price, size, block.timestamp));
        orders[orderId] = Order(msg.sender, orderType, price, size, OrderStatus.Open);

        emit NewOrder(orderId, msg.sender, orderType, price, size);
    }

    function fillOrder(bytes32 orderId, uint256 size) public {
        Order storage order = orders[orderId];
        require(order.status == OrderStatus.Open, "Order is not open");
        require(size > 0, "Size must be greater than 0");

        uint256 filled = size;
        if (filled > order.size) {
            filled = order.size;
        }

        uint256 cost = filled * order.price;
        require(cost <= address(this).balance, "Insufficient liquidity");

        order.size -= filled;
        if (order.size == 0) {
            order.status = OrderStatus.Filled;
        }

        (bool sent, ) = order.trader.call{value: cost}("");
        require(sent, "Failed to send Ether");

        emit OrderFilled(orderId, msg.sender, filled);
    }
}

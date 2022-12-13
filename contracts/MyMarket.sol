//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

interface IMarket {
    event CreateOrder(
        uint256 indexed id,
        uint256 indexed orderType,
        address indexed orderOwner,
        address nftToken,
        uint256 tokenId,
        address token,
        uint256 price,
        uint256 startTime,
        uint256 endTime,
        uint256 leastPercent
    );

    event ChangeOrder(
        uint256 indexed id,
        uint256 indexed orderType,
        address indexed orderOwner,
        address nftToken,
        uint256 tokenId,
        address token,
        uint256 price,
        uint256 startTime,
        uint256 endTime,
        uint256 leastPercent
    );

    event CompleteOrder(
        uint256 indexed id,
        uint256 indexed orderType,
        address indexed orderOwner,
        address payer,
        address nftToken,
        uint256 tokenId,
        address token,
        uint256 price,
        uint256 startTime,
        uint256 endTime,
        uint256 leastPercent
    );

    event CancelOrder(
        uint256 indexed id,
        uint256 indexed orderType,
        address indexed orderOwner,
        address nftToken,
        uint256 tokenId
    );

    event Bid(
        uint256 indexed id,
        uint256 indexed orderType,
        address indexed orderOwner,
        address bidder,
        uint256 bidTime,
        address token,
        uint256 price,
        address nftToken,
        uint256 tokenId
    );

    struct Order {
        uint256 id; //order id
        uint256 orderType; // 1: sell nft, 2: buy nft, 3: auction
        address orderOwner; //order owner
        address token; //pa token address
        uint256 price; //order price
        address nftToken; //nft token address
        uint256 tokenId; // token id
        uint256 startTime; // order start timestimp
        uint256 endTime; // order end timestimp
        uint256 leastPercent; // least Percent for auction
    }

    struct BidInfo {
        address bidder; // bidder
        uint256 price; // highest price
    }

    // read methods

    function name() external pure returns (string memory);

    function getTradeFeeRate() external view returns (uint256);

    function getOrder(uint256 orderId) external view returns (Order memory);

    function getBidInfo(uint256 orderId) external view returns (BidInfo memory);

    function getOrdersByOwner(address orderOwner)
        external
        view
        returns (Order[] memory);

    function getOrdersByNft(address nftToken, uint256 tokenId)
        external
        view
        returns (Order[] memory);

    // write methods
    
    function createOrder(
        uint256 orderType,
        address nftToken,
        uint256 tokenId,
        address token,
        uint256 price,
        uint256 timeLimit,
        uint256 leastPercent
    ) external returns (uint256);

    function cancelOrder(uint256 orderId) external;

    function fulfillOrder(uint256 orderId, uint256 price) external;

    function changeOrder(
        uint256 orderId,
        uint256 price,
        uint256 timeLimit,
        uint256 leastPercent
    ) external;

    function bid(uint256 orderId, uint256 price) external;

    function claim(uint256 orderId) external;
}

contract MyMarket is IMarket, Ownable, ERC1155Holder, ERC721Holder {
    using SafeMath for uint256;
    using Math for uint256;
    using SafeERC20 for IERC20;
    using EnumerableSet for EnumerableSet.UintSet;

    uint256 public tradeFeeRate = 50; // 0-200, default 50
    uint256 public constant rateBase = 1000; // base is always 1000

    using Counters for Counters.Counter;
    Counters.Counter private _orderCounter;
    mapping(uint256 => Order) public orderStorage;
    mapping(uint256 => BidInfo) public bidStorage;
    mapping(address => EnumerableSet.UintSet) private _orderIds;
    mapping(address => mapping(uint256 => EnumerableSet.UintSet))
        private _nftOrderIds;

    /********** mutable functions **********/

    function setTradeFeeRate(uint256 newTradeFeeRate) external onlyOwner {
        require(tradeFeeRate <= 200, "Trade fee rate exceed limit");
        tradeFeeRate = newTradeFeeRate;
    }

    function createOrder(
        uint256 orderType,
        address nftToken,
        uint256 tokenId,
        address token,
        uint256 price,
        uint256 timeLimit,
        uint256 leastPercent
    ) external override returns (uint256) {
        _orderCounter.increment();
        uint256 orderId = _orderCounter.current();
        Order memory order = Order({
            id: orderId,
            orderType: orderType,
            orderOwner: msg.sender,
            token: token,
            price: price,
            nftToken: nftToken,
            tokenId: tokenId,
            startTime: block.timestamp,
            endTime: block.timestamp + timeLimit * 1 days,
            leastPercent: leastPercent
        });

        require(price > 0, "Price invalid");
        require(timeLimit > 0, "TimeLimit invalid");
        require(orderType >= 1 && orderType <= 3, "OrderType invalid");
        // lock asset
        if (orderType == 1) {
            order.leastPercent = 0;
            _safeTransferERC721(
                order.nftToken,
                msg.sender,
                address(this),
                order.tokenId
            );
        } else if (orderType == 2) {
            order.leastPercent = 0;
            _safeTransferERC20(
                order.token,
                msg.sender,
                address(this),
                order.price
            );
        } else if (orderType == 3) {
            require(leastPercent > 0, "LeastPercent invalid");
            _safeTransferERC721(
                order.nftToken,
                msg.sender,
                address(this),
                order.tokenId
            );
        }
        emit CreateOrder(
            order.id,
            orderType,
            order.orderOwner,
            nftToken,
            tokenId,
            token,
            price,
            order.startTime,
            order.endTime,
            leastPercent
        );
        _addOrder(order);
        return order.id;
    }

    function _safeTransferERC20(
        address token,
        address from,
        address to,
        uint256 amount
    ) internal {
        uint256 balance = IERC20(token).balanceOf(from);
        require(balance >= amount, "Balance insufficient");
        IERC20(token).safeTransferFrom(from, to, amount);
    }

    function _safeTransferERC721(
        address nftToken,
        address from,
        address to,
        uint256 tokenId
    ) internal {
        address nftOwner = IERC721(nftToken).ownerOf(tokenId);
        require(from == nftOwner, "Nft owner invalid");
        IERC721(nftToken).safeTransferFrom(from, to, tokenId);
    }

    function _addOrder(Order memory order) private {
        orderStorage[order.id] = order;
        _orderIds[order.orderOwner].add(order.id);
        _nftOrderIds[order.nftToken][order.tokenId].add(order.id);
    }

    function _deleteOrder(Order memory order) private {
        delete orderStorage[order.id];
        _orderIds[order.orderOwner].remove(order.id);
        _nftOrderIds[order.nftToken][order.tokenId].remove(order.id);
    }

    function changeOrder(
        uint256 orderId,
        uint256 price,
        uint256 timeLimit,
        uint256 leastPercent
    ) external override {
        Order memory order = orderStorage[orderId];
        require(order.id > 0, "Order not exist");
        require(order.orderOwner == msg.sender, "Order owner not match");
        require(price > 0, "Price invalid");
        require(timeLimit > 0, "TimeLimit invalid");

        // change locked token
        if (order.orderType == 2 && order.price != price) {
            if (price > order.price) {
                _safeTransferERC20(
                    order.token,
                    msg.sender,
                    address(this),
                    price.sub(order.price)
                );
            } else {
                _safeTransferERC20(
                    order.token,
                    address(this),
                    msg.sender,
                    order.price.sub(price)
                );
            }
        }

        if (order.orderType == 3) {
            require(leastPercent > 0, "LeastPercent invalid");
            // check bid info
            BidInfo memory bidInfo = bidStorage[orderId];
            require(bidInfo.price == 0, "Bid should be Null");
            order.leastPercent = leastPercent;
        }

        order.price = price;
        order.endTime = block.timestamp + timeLimit * 1 days;
        emit ChangeOrder(
            order.id,
            order.orderType,
            order.orderOwner,
            order.nftToken,
            order.tokenId,
            order.token,
            order.price,
            order.startTime,
            order.endTime,
            order.leastPercent
        );
        orderStorage[order.id] = order;
    }

    function cancelOrder(uint256 orderId) external override {
        Order memory order = orderStorage[orderId];
        require(order.id > 0, "Order not exist");
        require(order.orderOwner == msg.sender, "Order owner not match");
        // unlock asset
        if (order.orderType == 1) {
            _safeTransferERC721(
                order.nftToken,
                address(this),
                order.orderOwner,
                order.tokenId
            );
        } else if (order.orderType == 2) {
            _safeTransferERC20(
                order.token,
                address(this),
                order.orderOwner,
                order.price
            );
        } else if (order.orderType == 3) {
            // check bid info
            BidInfo memory bidInfo = bidStorage[orderId];
            require(bidInfo.price == 0, "Bid should be Null");
            _safeTransferERC721(
                order.nftToken,
                address(this),
                order.orderOwner,
                order.tokenId
            );
        }

        emit CancelOrder(
            order.id,
            order.orderType,
            order.orderOwner,
            order.nftToken,
            order.tokenId
        );
        _deleteOrder(order);
    }

    function fulfillOrder(uint256 orderId, uint256 price) external override {
        Order memory order = orderStorage[orderId];
        require(order.id > 0, "Order not exist");
        require(order.price == price, "Price not match");
        require(block.timestamp <= order.endTime, "Order expired");
        require(
            order.orderType >= 1 && order.orderType <= 2,
            "OrderType invalid"
        );
        if (order.orderType == 1) {
            _payToken(order);
        } else if (order.orderType == 2) {
            _payNft(order);
        }

        emit CompleteOrder(
            order.id,
            order.orderType,
            order.orderOwner,
            msg.sender,
            order.nftToken,
            order.tokenId,
            order.token,
            order.price,
            order.startTime,
            order.endTime,
            order.leastPercent
        );
        _deleteOrder(order);
    }

    function _payToken(Order memory order) internal {
        uint256 fee = order.price.mul(tradeFeeRate).div(rateBase);
        _safeTransferERC20(order.token, msg.sender, owner(), fee);
        _safeTransferERC20(
            order.token,
            msg.sender,
            order.orderOwner,
            order.price.sub(fee)
        );
        _safeTransferERC721(
            order.nftToken,
            address(this),
            msg.sender,
            order.tokenId
        );
    }

    function _payNft(Order memory order) internal {
        _safeTransferERC721(
            order.nftToken,
            msg.sender,
            order.orderOwner,
            order.tokenId
        );
        uint256 fee = order.price.mul(tradeFeeRate).div(rateBase);
        _safeTransferERC20(order.token, address(this), owner(), fee);
        _safeTransferERC20(
            order.token,
            address(this),
            order.orderOwner,
            order.price.sub(fee)
        );
    }

    function bid(uint256 orderId, uint256 price) external override {
        Order memory order = orderStorage[orderId];
        require(order.id > 0, "Order not exist");
        require(price >= order.price, "Price needs to exceed reserve price");
        require(block.timestamp <= order.endTime, "Order expired");
        require(order.orderType == 3, "OrderType invalid");
        BidInfo memory currentBid = bidStorage[orderId];
        if (currentBid.price > 0) {
            require(
                price >=
                    currentBid.price.add(
                        currentBid.price.mul(order.leastPercent).div(rateBase)
                    ),
                "Bid price low"
            );
            // refund current bid
            _safeTransferERC20(
                order.token,
                address(this),
                currentBid.bidder,
                currentBid.price
            );
        }

        BidInfo memory bidInfo = BidInfo({bidder: msg.sender, price: price});
        _safeTransferERC20(
            order.token,
            bidInfo.bidder,
            address(this),
            bidInfo.price
        );

        emit Bid(
            order.id,
            order.orderType,
            order.orderOwner,
            msg.sender,
            block.timestamp,
            order.token,
            order.price,
            order.nftToken,
            order.tokenId
        );
        bidStorage[order.id] = bidInfo;
    }

    function claim(uint256 orderId) external override {
        Order memory order = orderStorage[orderId];
        require(order.id > 0, "Order not exist");
        require(block.timestamp > order.endTime, "Order is in auction time");
        require(order.orderType == 3, "OrderType invalid");
        BidInfo memory currentBid = bidStorage[orderId];
        require(currentBid.price > 0, "Bid not exist");
        require(
            msg.sender == order.orderOwner || msg.sender == currentBid.bidder,
            "Only order owner or bidder can claim"
        );

        uint256 fee = currentBid.price.mul(tradeFeeRate).div(rateBase);
        _safeTransferERC20(order.token, address(this), owner(), fee);
        _safeTransferERC20(
            order.token,
            address(this),
            order.orderOwner,
            currentBid.price.sub(fee)
        );
        _safeTransferERC721(
            order.nftToken,
            address(this),
            currentBid.bidder,
            order.tokenId
        );

        emit CompleteOrder(
            order.id,
            order.orderType,
            order.orderOwner,
            currentBid.bidder,
            order.nftToken,
            order.tokenId,
            order.token,
            currentBid.price,
            order.startTime,
            order.endTime,
            order.leastPercent
        );
        delete bidStorage[order.id];
        _deleteOrder(order);
    }

    /********** view functions **********/

    function name() external pure override returns (string memory) {
        return "NFT Market";
    }

    function getTradeFeeRate() external view override returns (uint256) {
        return tradeFeeRate;
    }

    function getOrder(uint256 orderId)
        external
        view
        override
        returns (Order memory)
    {
        return orderStorage[orderId];
    }

    function getBidInfo(uint256 orderId)
        external
        view
        override
        returns (BidInfo memory)
    {
        return bidStorage[orderId];
    }

    function getOrdersByOwner(address orderOwner)
        external
        view
        override
        returns (Order[] memory)
    {
        uint256 length = _orderIds[orderOwner].length();
        Order[] memory list = new Order[](length);
        for (uint256 i = 0; i < length; i++) {
            list[i] = orderStorage[_orderIds[orderOwner].at(i)];
        }
        return list;
    }

    function getOrdersByNft(address nftToken, uint256 tokenId)
        external
        view
        override
        returns (Order[] memory)
    {
        uint256 length = _nftOrderIds[nftToken][tokenId].length();
        Order[] memory list = new Order[](length);
        for (uint256 i = 0; i < length; i++) {
            list[i] = orderStorage[_nftOrderIds[nftToken][tokenId].at(i)];
        }
        return list;
    }
}

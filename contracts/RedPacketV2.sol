//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma abicoder v2;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/interfaces/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";

contract RedPacketV2 is Initializable, OwnableUpgradeable {
    using SafeMath for uint256;
    using Math for uint256;
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.UintSet;
    using ECDSAUpgradeable for bytes32;

    struct RedPacket {
        uint256 id; //red packet id
        string groupId; //chat group Id
        address token; //token address
        address sender; //red packet sender
        uint256 amount; //red packet amount
        uint256 sendDate; //send time
        uint256 expireDate; //expire time
        uint256 quantity; //max red packet distribute count
        uint256 remainAmount; //red packet remain amount
        uint256 remainQuantity; //red packet remain count
        uint256 status;  // 0: unclaimed(including partially claimed); 1: all claimed; 2: refunded（refund the remaining amount when times out）
        string description; 
        uint256 kind; //0: random; 1: normal
    }

    struct RedPacketExpireInfo {
      uint256 id; //red packet id
      uint256 expireDate; //expire time
    }

    struct RP {
        address receiver; //red packet receiver
        uint256 id; //red packet id
        uint256 salt; //for random red packet
    }

    uint256 public fee;
    uint256 public delegateFeeRate;  //default 5000, that means delegateFeeRate is 50%
    uint256 constant public rateBase = 10000;         //base is always 10000
    RedPacket[] public redPackets;
    mapping(address => EnumerableSetUpgradeable.UintSet) private _userNormalRedPacketIds;
    address public delegator;
    mapping(address => bool) public authorization;
    uint256 public sigNumber;
    mapping(uint256 => mapping(address => bool)) public receiveRecords;
    RedPacketExpireInfo[] public redPacketExpireInfos;

    modifier onlyDelegator() {
        require(delegator == msg.sender, "!delegator");
        _;
    }

    event RedPacketSent(
        uint256 indexed id,
        string groupId,
        address token,
        address sender,
        uint256 amount,
        uint256 sendDate,
        uint256 expireDate,
        uint256 quantity,
        string description,
        uint256 kind
    );

    event RedPacketReceived(
        uint256 indexed id,
        string groupId,
        address token,
        address receiver,
        uint256 amount,
        uint256 receiveDate
    );

    event Refund(
        uint256 indexed id,
        string groupId,
        address to,
        uint256 amount,
        uint256 refundDate
    );

    modifier validRedPacketId(uint256 redPacketId) {
      require(redPacketId < redPackets.length, "Invalid red packet id");
      _;
    }

    function initialize() external initializer {
      __Context_init_unchained();
      __Ownable_init_unchained();
      fee = 1e16;
      delegateFeeRate = 5000;
      sigNumber = 1;
    }

    /********** mutable functions **********/

    function setSignatureNum(uint256 num) public onlyOwner {
        sigNumber = num;
    }

    function addAuthorization(address addr) public onlyOwner {
        authorization[addr] = true;
    }

    function removeAuthorization(address addr) public onlyOwner {
        delete authorization[addr];
    }

    function setDelegator(address _delegator) external onlyOwner {
      delegator = _delegator;
    }

    function setFee(uint256 newFee) external onlyOwner {
      fee = newFee;
    }

    function setDelegateFeeRate(uint256 newDelegateFeeRate) external onlyOwner {
      require(delegateFeeRate <= rateBase, "Delegate fee rate exceed rate base");
      delegateFeeRate = newDelegateFeeRate;
    }

    function sendRedPacket(
      address token,
      string memory groupId,
      uint256 amount,
      uint256 expireInterval,
      uint256 quantity,
      string memory description,
      uint256 kind
    ) external payable {
      require(msg.value >=fee, "Not enough transaction fee");
      require(amount > 0, "Amount should be greater than 0");
      require(quantity > 0, "Quantity should be greater than 0");
      require(expireInterval > 0, "expireInterval should be greater than 0");
      require(kind == 0 || kind == 1, "kind should be 0 or 1");
      sendValue(payable(delegator), msg.value.mul(delegateFeeRate).div(rateBase));

      //Compatible with burnable token, amount will be detemined by transfer difference
      uint256 realAmount = transferFromSupportingFeeOnTransferTokens(token, msg.sender, address(this), amount);
      require(realAmount > 0, "Amount should be greater than 0");
      uint256 expireDate = block.timestamp.add(expireInterval);
      uint256 id = addRedPacket(msg.sender, token, groupId, realAmount, expireDate, quantity, description, kind);
      addExpireInfo(id, expireDate);
      emit RedPacketSent(id, groupId, token, msg.sender, realAmount, block.timestamp, expireDate, quantity, description, kind);
    }

    function addExpireInfo(uint256 id, uint256 expireDate) internal {
      RedPacketExpireInfo memory rpei =
        RedPacketExpireInfo({
          id: id,
          expireDate: expireDate
        });
      redPacketExpireInfos.push(rpei);
    }

    function removeExpireInfo(uint256 id) internal {
      uint256 length = redPacketExpireInfos.length;
      for (uint256 i = 0; i < length; i++) {
        if (redPacketExpireInfos[i].id == id) {
          redPacketExpireInfos[i] = redPacketExpireInfos[length - 1];
          redPacketExpireInfos.pop();
          break;
        }
      }
    }

    function addRedPacket(
      address sender,
      address token,
      string memory groupId,
      uint256 amount,
      uint256 expireDate,
      uint256 quantity,
      string memory description,
      uint256 kind
    ) internal returns (uint256) {
      uint256 id = redPackets.length;
      RedPacket memory rp =
        RedPacket({
          id: id,
          groupId: groupId,
          token: token,
          sender: sender,
          amount: amount,
          sendDate: block.timestamp,
          expireDate: expireDate,
          quantity: quantity,
          remainAmount: amount,
          remainQuantity: quantity,
          status: 0,
          description: description,
          kind: kind
        });
      redPackets.push(rp);
      _userNormalRedPacketIds[sender].add(id);
      return id;
    }

    function sendValue(address payable recipient, uint256 amount) internal {
      require(address(this).balance >= amount, "insufficient balance");
            (bool success, ) = recipient.call{value: amount}("");
      require(success, "unable to send value, recipient may have reverted");
    }

    function receiveRedPacket(bytes calldata payload, bytes[] calldata sigs) external {
      require(sigs.length == sigNumber, "signature num error");
      RP memory rp = abi.decode(payload, (RP));
      bytes32 hash = keccak256(payload).toEthSignedMessageHash();
      address auth = address(0);
      for (uint256 i = 0; i < sigs.length; i++) {
          address addr = hash.recover(sigs[i]);
          require(addr > auth, "signature order error");
          require(authorization[addr], "invalid signature");
          auth = addr;
      }
      require(rp.id < redPackets.length, "Invalid red packet id");
      require(rp.receiver == msg.sender, "sender is not receiver");
      RedPacket storage redPacket = redPackets[rp.id];
      require(redPacket.status == 0, "status error");
      require(redPacket.remainAmount > 0, "no more remaining amount");
      require(redPacket.remainQuantity > 0, "no more remaining quantity");
      require(block.timestamp <= redPacket.expireDate, "red packet expired");
      require(!receiveRecords[rp.id][msg.sender], "duplicated receive");
      uint dividend = 0;
      if(redPacket.kind == 1) {
        if(redPacket.remainQuantity > 1) {
          dividend = redPacket.amount.div(redPacket.quantity);
          redPacket.remainAmount = redPacket.remainAmount.sub(dividend);
          redPacket.remainQuantity = redPacket.remainQuantity.sub(1);
        } else {
          dividend = redPacket.remainAmount;
          redPacket.remainAmount = 0;
          redPacket.remainQuantity = 0;
          redPacket.status = 1;
          removeExpireInfo(rp.id);
        }
      } else {
        if(redPacket.remainQuantity > 1) {
          dividend = getRandomDividend(redPacket.remainAmount, redPacket.remainQuantity, rp.salt);
          redPacket.remainAmount = redPacket.remainAmount.sub(dividend);
          redPacket.remainQuantity = redPacket.remainQuantity.sub(1);
        } else {
          dividend = redPacket.remainAmount;
          redPacket.remainAmount = 0;
          redPacket.remainQuantity = 0;
          redPacket.status = 1;
          removeExpireInfo(rp.id);
        }
      }
      uint256 realDividend = transferSupportingFeeOnTransferTokens(redPacket.token, msg.sender, dividend);
      receiveRecords[rp.id][msg.sender] = true;
      emit RedPacketReceived(redPacket.id, redPacket.groupId, redPacket.token, msg.sender, realDividend, block.timestamp);
    }

    function getRandomDividend(uint256 remainAmount, uint256 remainQuantity, uint256 salt) view internal returns(uint256) {
      uint256 rand = roll(salt);
      uint256 min = remainAmount.div(remainQuantity.mul(2));
      uint256 max1 = remainAmount.mul(8).div(10);
      uint256 max2 = remainAmount.mul(2).div(remainQuantity);
      uint256 max = max1.min(max2);
      return rand.mul(max.sub(min)).div(10000).add(min);
    }

    function roll(uint256 salt) view public returns (uint256) {
        uint256 seed = uint256(keccak256(abi.encode(salt, blockhash(block.number)))); // Hash user seed and blockhash
        return seed.mod(10000);
    }

    function refund(uint256 id) external onlyDelegator validRedPacketId(id) {
      RedPacket storage redPacket = redPackets[id];
      require(redPacket.status == 0, "status error");
      require(block.timestamp > redPacket.expireDate, "not expired yet");
      require(redPacket.remainAmount > 0, "no value to refund");
      require(redPacket.remainQuantity > 0, "all received");
      uint256 realAmount = transferSupportingFeeOnTransferTokens(redPacket.token, redPacket.sender, redPacket.remainAmount);
      redPacket.status = 2;
      redPacket.remainAmount = 0;
      redPacket.remainQuantity = 0;
      removeExpireInfo(id);
      emit Refund(redPacket.id, redPacket.groupId, redPacket.sender, realAmount, block.timestamp);
    }

    function withdraw(
      address payable recipient,
      address token,
      uint256 amount
    ) external onlyOwner {
      if (token == address(0)) {
        sendValue(recipient, amount);
      } else {
        IERC20Upgradeable(token).safeTransfer(recipient, amount);
      }
    }

    function transferSupportingFeeOnTransferTokens(address token, address to, uint256 amount) internal returns(uint256){
      uint256 oldRecipientBalance = IERC20Upgradeable(token).balanceOf(to);
      IERC20Upgradeable(token).safeTransfer(to, amount);
      uint256 newRecipientBalance = IERC20Upgradeable(token).balanceOf(to);
      uint256 realAmount = newRecipientBalance.sub(oldRecipientBalance);
      return realAmount;
    }

    function transferFromSupportingFeeOnTransferTokens(address token, address from, address to, uint256 amount) internal returns(uint256){
      uint256 oldRecipientBalance = IERC20Upgradeable(token).balanceOf(to);
      IERC20Upgradeable(token).safeTransferFrom(from, to, amount);
      uint256 newRecipientBalance = IERC20Upgradeable(token).balanceOf(to);
      uint256 realAmount = newRecipientBalance.sub(oldRecipientBalance);
      return realAmount;
    }

    receive() external payable {}

    fallback() external payable {}

    /********** view functions **********/

    function encodeRP(address _receiver, uint256 _id, uint256 _salt) public pure returns (bytes memory) {
        RP memory rp;
        rp.receiver = _receiver;
        rp.id = _id;
        rp.salt = _salt;
        return abi.encode(rp);
    }

    function getExpiredButNotRefundRedPackets() public view returns (uint256[] memory){
      uint256 retLength = getExpiredButNotRefundRedPacketsCount();
      uint256[] memory ret = new uint256[](retLength);
      uint256 retIndex = 0;
      for (uint256 i = 0; i < redPacketExpireInfos.length; i++) {
        if (redPacketExpireInfos[i].expireDate < block.timestamp) {
          ret[retIndex] = redPacketExpireInfos[i].id;
          retIndex = retIndex.add(1);
        }
      }
      return ret;
    }

    function getExpiredButNotRefundRedPacketsCount() public view returns (uint256){
      uint256 retLength = 0;
      uint256 length = redPacketExpireInfos.length;
      for (uint256 i = 0; i < length; i++) {
        if (redPacketExpireInfos[i].expireDate < block.timestamp) {
          retLength = retLength.add(1);
        }
      }
      return retLength;
    }

    function getTotalRedPacketCount() public view returns (uint256) {
      return redPackets.length;
    }

    function getRedPackets(uint256 start, uint256 end) public view returns (RedPacket[] memory) {
      if (end >= redPackets.length) {
        end = redPackets.length - 1;
      }
      uint256 length = end - start + 1;
      RedPacket[] memory ret = new RedPacket[](length);
      uint256 currentIndex = 0;
      for (uint256 i = start; i <= end; i++) {
        ret[currentIndex] = redPackets[i];
        currentIndex++;
      }
      return ret;
    }

    function normalRedPacketCountForUser(address user) public view returns (uint256) {
      return _userNormalRedPacketIds[user].length();
    }

    function normalRedPacketsForUser(address user) public view returns (RedPacket[] memory) {
      uint256 length = _userNormalRedPacketIds[user].length();
      RedPacket[] memory userRedPackets = new RedPacket[](length);
      for (uint256 i = 0; i < length; i++) {
        userRedPackets[i] = redPackets[_userNormalRedPacketIds[user].at(i)];
      }
      return userRedPackets;
    }

    function normalRedPacketForUserAtIndex(address user, uint256 index) public view returns (RedPacket memory) {
      require(normalRedPacketCountForUser(user) > index, "Invalid index");
      return redPackets[_userNormalRedPacketIds[user].at(index)];
    }

    function getNormalRedPacketsForUser(
      address user,
      uint256 start,
      uint256 end
    ) public view returns (RedPacket[] memory) {
      if (end >= _userNormalRedPacketIds[user].length()) {
        end = _userNormalRedPacketIds[user].length() - 1;
      }
      uint256 length = end - start + 1;
      RedPacket[] memory userRedPackets = new RedPacket[](length);
      uint256 currentIndex = 0;
      for (uint256 i = start; i <= end; i++) {
        userRedPackets[currentIndex] = redPackets[_userNormalRedPacketIds[user].at(i)];
        currentIndex++;
      }
      return userRedPackets;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import { Types } from "./utils/Types.sol";
import {
    ReentrancyGuard
} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";
interface IFilNoteContract {
    function getNote(uint64 id) external view returns (Types.Note memory);
    function completeNote(uint64 id) external returns (uint64);
    function defaultNote(uint64 id) external returns (uint64);
    function owner() external view returns (address);
}

contract ProtocolsContract is ReentrancyGuard {
    uint64 private immutable _ID;
    address private immutable _CREATOR;
    address private immutable _INVESTOR;
    address private immutable _FIL_NOTE_CONTRACT;

    uint256 private _fundingAmount;
    uint256 private _poolAmount;
    bool private _stopped;

    constructor(
        uint64 noteId,
        address noteCreator,
        address noteInvestor
    ) payable {
        _ID = noteId;
        _CREATOR = noteCreator;
        _INVESTOR = noteInvestor;
        _fundingAmount = msg.value;
        _FIL_NOTE_CONTRACT = msg.sender;
        _poolAmount = 0;
        emit ProtocolCreated(noteId, noteCreator, noteInvestor);
    }

    event Received(address indexed sender, uint256 value);
    event WithdrawFundingAmount(address indexed creator, uint256 amount);
    event ProtocolCreated(
        uint64 indexed noteId,
        address indexed creator,
        address indexed investor
    );
    event WithdrawPoolAmount(address indexed account, uint256 amount);
    event Stopped(uint256 payout);

    /**
     * @notice Receive ETH payments to increase pool amount [中文: 接收ETH支付以增加池金额]
     * @dev Allows anyone to send ETH to this contract to increase the pool [中文: 允许任何人向此合约发送ETH以增加池]
     * @custom:permission Public function, anyone can send ETH [中文: 公共函数，任何人都可以发送ETH]
     * @custom:security No access control - this is intentional design [中文: 无访问控制 - 这是有意设计]
     * @custom:note This function allows external parties to contribute to the pool [中文: 此函数允许外部方为池做出贡献]
     * @custom:emits Received event with sender address and value [中文: 发出包含发送者地址和金额的Received事件]
     */
    receive() external payable {
        _poolAmount += msg.value;
        emit Received(msg.sender, msg.value);
    }

    modifier whenNotStopped() {
        if (_stopped) revert Types.NotPermission();
        _;
    }

    modifier onlyCreator() {
        if (msg.sender != _CREATOR) revert Types.NotPermission();
        _;
    }

    modifier onlyInvestor() {
        if (msg.sender != _INVESTOR) revert Types.NotPermission();
        _;
    }

    modifier onlyFilNoteContract() {
        if (msg.sender != _FIL_NOTE_CONTRACT) revert Types.NotPermission();
        _;
    }

    /**
     * @notice Calculate minimum reserve amount for a note [中文: 计算票据的最低储备金额]
     * @dev Calculates the minimum reserve as target amount plus interest [中文: 计算最低储备为目标金额加上利息]
     * @param n The note structure containing interest rate and borrowing days [中文: 包含利率和借款天数的票据结构]
     * @return uint256 The minimum reserve amount in wei [中文: 最低储备金额，以wei为单位]
     * @custom:security Uses Math.mulDiv for precise interest calculation [中文: 使用Math.mulDiv进行精确的利息计算]
     * @custom:note Formula: targetAmount + (targetAmount * interestRateBps * borrowingDays) / (10000 * 365) [中文: 公式：targetAmount + (targetAmount * interestRateBps * borrowingDays) / (10000 * 365)]
     */
    function _minReserve(Types.Note memory n) internal pure returns (uint256) {
        uint256 num = uint256(n.interestRateBps) * uint256(n.borrowingDays);
        uint256 interest = Math.mulDiv(n.targetAmount, num, (10000 * 365));
        return n.targetAmount + interest;
    }

    /**
     * @notice Get protocol information from FilNote contract [中文: 从FilNote合约获取协议信息]
     * @dev Retrieves the note information associated with this protocol contract [中文: 检索与此协议合约关联的票据信息]
     * @return Types.Note memory The note structure containing all protocol details [中文: 包含所有协议详情的票据结构]
     * @custom:permission Public view function, anyone can call [中文: 公共视图函数，任何人都可以调用]
     * @custom:gas-optimization View function with no state changes [中文: 视图函数，无状态更改]
     */
    function getProtocolInfo() public view returns (Types.Note memory) {
        return IFilNoteContract(_FIL_NOTE_CONTRACT).getNote(_ID);
    }
    /**
     * @notice Withdraw funding amount by creator [中文: 创建者提取资金金额]
     * @dev Allows the creator to withdraw the initial funding amount when note is active [中文: 允许创建者在票据处于活跃状态时提取初始资金金额]
     * @custom:permission Only creator can call [中文: 只有创建者可以调用]
     * @custom:modifier Uses nonReentrant to prevent reentrancy attacks [中文: 使用nonReentrant防止重入攻击]
     * @custom:modifier Uses whenNotStopped to ensure protocol is active [中文: 使用whenNotStopped确保协议处于活跃状态]
     * @custom:reverts Types.InvalidNoteStatus() if note is not in ACTIVE status [中文: 如果票据不在ACTIVE状态则回滚Types.InvalidNoteStatus()]
     * @custom:reverts Types.InvalidAmount() if funding amount is zero [中文: 如果资金金额为零则回滚Types.InvalidAmount()]
     * @custom:reverts Types.TransferFailed() if ETH transfer to creator fails [中文: 如果向创建者转账ETH失败则回滚Types.TransferFailed()]
     * @custom:security Follows CEI pattern: state updated before external call [中文: 遵循CEI模式：在外部调用之前更新状态]
     * @custom:emits WithdrawFundingAmount event with creator address and amount [中文: 发出包含创建者地址和金额的WithdrawFundingAmount事件]
     */
    function withdrawFundingAmount()
        public
        nonReentrant
        whenNotStopped
        onlyCreator
    {
        Types.Note memory note = getProtocolInfo();
        if (note.status != uint8(Types.NoteStatus.ACTIVE))
            revert Types.InvalidNoteStatus();
        if (_fundingAmount == 0) revert Types.InvalidAmount();
        uint256 payout = _fundingAmount;
        _fundingAmount = 0;
        (bool ok, ) = _CREATOR.call{ value: payout }("");
        if (!ok) revert Types.TransferFailed();
        emit WithdrawFundingAmount(_CREATOR, payout);
    }

    /**
     * @notice Withdraw pool amount by service provider (creator) [中文: 服务提供者(创建者)提取池金额]
     * @dev Allows the creator to withdraw from the pool while maintaining minimum reserve [中文: 允许创建者从池中提取，同时保持最低储备]
     * @param amount The amount to withdraw from the pool [中文: 从池中提取的金额]
     * @custom:permission Only creator can call [中文: 只有创建者可以调用]
     * @custom:modifier Uses nonReentrant to prevent reentrancy attacks [中文: 使用nonReentrant防止重入攻击]
     * @custom:modifier Uses whenNotStopped to ensure protocol is active [中文: 使用whenNotStopped确保协议处于活跃状态]
     * @custom:reverts Types.InvalidAmount() if amount is zero or insufficient pool balance [中文: 如果金额为零或池余额不足则回滚Types.InvalidAmount()]
     * @custom:reverts Types.InvalidNoteStatus() if note is not in ACTIVE status [中文: 如果票据不在ACTIVE状态则回滚Types.InvalidNoteStatus()]
     * @custom:reverts Types.TransferFailed() if ETH transfer fails [中文: 如果ETH转账失败则回滚Types.TransferFailed()]
     * @custom:security Checks pool >= amount before subtraction to prevent underflow [中文: 在减法前检查pool >= amount以防止下溢]
     * @custom:security Ensures minimum reserve is maintained after withdrawal [中文: 确保提取后保持最低储备]
     */
    function spWithdrawPoolAmount(
        uint256 amount
    ) public nonReentrant whenNotStopped onlyCreator {
        if (amount == 0) revert Types.InvalidAmount();
        Types.Note memory note = getProtocolInfo();
        uint256 minReserve = _minReserve(note);
        uint256 pool = _poolAmount;
        if (note.status != uint8(Types.NoteStatus.ACTIVE)) {
            revert Types.InvalidNoteStatus();
        }
        // Check pool >= amount before subtraction to prevent underflow
        // [中文: 在减法前检查pool >= amount以防止下溢]
        if (pool < amount) revert Types.InvalidAmount();
        if (pool - amount < minReserve) {
            revert Types.InvalidAmount();
        }
        _poolAmount = pool - amount;
        (bool ok, ) = _CREATOR.call{ value: amount }("");
        if (!ok) revert Types.TransferFailed();
        emit WithdrawPoolAmount(msg.sender, amount);
    }

    /**
     * @notice Withdraw pool amount by investor after maturity [中文: 投资者在到期后提取池金额]
     * @dev Allows investor to withdraw minimum reserve after note expiry, following CEI pattern [中文: 允许投资者在票据到期后提取最低储备，遵循CEI模式]
     * @custom:permission Only investor can call [中文: 只有投资者可以调用]
     * @custom:modifier Uses nonReentrant to prevent reentrancy attacks [中文: 使用nonReentrant防止重入攻击]
     * @custom:modifier Uses whenNotStopped to ensure protocol is active [中文: 使用whenNotStopped确保协议处于活跃状态]
     * @custom:reverts Types.InvalidNoteStatus() if note is not in ACTIVE status [中文: 如果票据不在ACTIVE状态则回滚Types.InvalidNoteStatus()]
     * @custom:reverts Types.NotMatured() if note has not reached expiry time [中文: 如果票据尚未到达到期时间则回滚Types.NotMatured()]
     * @custom:reverts Types.TransferFailed() if ETH transfer fails [中文: 如果ETH转账失败则回滚Types.TransferFailed()]
     * @custom:security Follows CEI pattern: Checks -> Effects -> Interactions [中文: 遵循CEI模式：检查 -> 效果 -> 交互]
     * @custom:security All state updates completed before external calls [中文: 所有状态更新在外部调用之前完成]
     * @custom:emits WithdrawPoolAmount event with investor address and amount [中文: 发出包含投资者地址和金额的WithdrawPoolAmount事件]
     */
    function investorWithdrawPoolAmount()
        public
        nonReentrant
        whenNotStopped
        onlyInvestor
    {
        // Checks: Validate note status and maturity
        // [中文: 检查：验证票据状态和到期时间]
        Types.Note memory note = getProtocolInfo();
        if (note.status != uint8(Types.NoteStatus.ACTIVE))
            revert Types.InvalidNoteStatus();
        if (block.timestamp < note.expiryTime) revert Types.NotMatured();

        // Calculate payout amount
        // [中文: 计算支付金额]
        uint256 payout = _minReserve(note);
        uint256 balance = _poolAmount;
        uint256 payoutAmount;
        if (balance >= payout) {
            payoutAmount = payout;
        } else {
            payoutAmount = balance;
        }

        // Effects: Update state before external calls (CEI pattern)
        // [中文: 效果：在外部调用之前更新状态（CEI模式）]
        _poolAmount -= payoutAmount;

        // Interactions: External calls after state updates
        // [中文: 交互：状态更新后的外部调用]
        (bool ok, ) = _INVESTOR.call{ value: payoutAmount }("");
        if (!ok) revert Types.TransferFailed();

        // Update note status based on payout
        // [中文: 根据支付金额更新票据状态]
        if (payoutAmount == payout) {
            IFilNoteContract(_FIL_NOTE_CONTRACT).completeNote(_ID);
        } else {
            IFilNoteContract(_FIL_NOTE_CONTRACT).defaultNote(_ID);
        }

        emit WithdrawPoolAmount(_INVESTOR, payoutAmount);
    }

    /**
     * @notice Stop the protocol contract and distribute remaining funds [中文: 停止协议合约并分配剩余资金]
     * @dev Called by FilNote contract to stop protocol operations and send all funds to investor [中文: 由FilNote合约调用以停止协议操作并将所有资金发送给投资者]
     * @custom:permission Only FilNote contract can call [中文: 只有FilNote合约可以调用]
     * @custom:modifier Uses nonReentrant to prevent reentrancy attacks [中文: 使用nonReentrant防止重入攻击]
     * @custom:reverts Types.InvalidAmount() if contract balance is zero [中文: 如果合约余额为零则回滚Types.InvalidAmount()]
     * @custom:reverts Types.TransferFailed() if ETH transfer to investor fails [中文: 如果向投资者转账ETH失败则回滚Types.TransferFailed()]
     * @custom:security Follows CEI pattern: all state updates before external call [中文: 遵循CEI模式：所有状态更新在外部调用之前]
     * @custom:security Sets _stopped flag to prevent further operations [中文: 设置_stopped标志以防止进一步操作]
     * @custom:emits Stopped event with payout amount [中文: 发出包含支付金额的Stopped事件]
     */
    function stopProtocol() public nonReentrant onlyFilNoteContract {
        _stopped = true;
        uint256 payout = address(this).balance;
        if (payout == 0) revert Types.InvalidAmount();
        _poolAmount = 0;
        _fundingAmount = 0;
        (bool ok, ) = _INVESTOR.call{ value: payout }("");
        if (!ok) revert Types.TransferFailed();
        emit Stopped(payout);
    }

    /**
     * @notice Get contract information including funding and pool amounts [中文: 获取合约信息，包括资金和池金额]
     * @dev Returns the current funding amount and pool amount for this protocol [中文: 返回此协议的当前资金金额和池金额]
     * @return Types.ProtocolInfo memory Structure containing fundingAmount and poolAmount [中文: 包含fundingAmount和poolAmount的结构]
     * @custom:permission Public view function, anyone can call [中文: 公共视图函数，任何人都可以调用]
     * @custom:gas-optimization View function with no state changes [中文: 视图函数，无状态更改]
     */
    function getContractInfo() public view returns (Types.ProtocolInfo memory) {
        return
            Types.ProtocolInfo({
                fundingAmount: _fundingAmount,
                poolAmount: _poolAmount
            });
    }
}

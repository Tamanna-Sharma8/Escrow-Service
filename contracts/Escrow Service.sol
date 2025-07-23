// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title Escrow Service
 * @dev A decentralized escrow service for secure peer-to-peer transactions
 * @author Tamanna Sh
 */
contract Project is ReentrancyGuard, Ownable {
    
    // Struct to represent an escrow transaction
    struct EscrowTransaction {
        address buyer;
        address seller;
        uint256 amount;
        bool isCompleted;
        bool isDisputed;
        uint256 createdAt;
        string description;
    }
    
    // Mapping to store escrow transactions
    mapping(uint256 => EscrowTransaction) public escrowTransactions;
    
    // Counter for transaction IDs
    uint256 public transactionCounter;
    
    // Service fee percentage (in basis points, e.g., 250 = 2.5%)
    uint256 public serviceFeeRate = 250;
    
    // Maximum service fee rate (5%)
    uint256 public constant MAX_SERVICE_FEE_RATE = 500;
    
    // Events
    event EscrowCreated(
        uint256 indexed transactionId,
        address indexed buyer,
        address indexed seller,
        uint256 amount,
        string description
    );
    
    event EscrowCompleted(
        uint256 indexed transactionId,
        address indexed buyer,
        address indexed seller,
        uint256 amount
    );
    
    event EscrowDisputed(
        uint256 indexed transactionId,
        address indexed disputeInitiator
    );
    
    event ServiceFeeUpdated(uint256 oldRate, uint256 newRate);
    
    // Modifiers
    modifier onlyBuyer(uint256 _transactionId) {
        require(
            msg.sender == escrowTransactions[_transactionId].buyer,
            "Only buyer can call this function"
        );
        _;
    }
    
    modifier onlySeller(uint256 _transactionId) {
        require(
            msg.sender == escrowTransactions[_transactionId].seller,
            "Only seller can call this function"
        );
        _;
    }
    
    modifier transactionExists(uint256 _transactionId) {
        require(
            _transactionId < transactionCounter,
            "Transaction does not exist"
        );
        _;
    }
    
    modifier notCompleted(uint256 _transactionId) {
        require(
            !escrowTransactions[_transactionId].isCompleted,
            "Transaction already completed"
        );
        _;
    }
    
    constructor() Ownable(msg.sender) {}
    
    /**
     * @dev Creates a new escrow transaction
     * @param _seller Address of the seller
     * @param _description Description of the transaction
     * @return transactionId The ID of the created transaction
     */
    function createEscrow(
        address _seller,
        string memory _description
    ) external payable nonReentrant returns (uint256) {
        require(msg.value > 0, "Amount must be greater than 0");
        require(_seller != address(0), "Invalid seller address");
        require(_seller != msg.sender, "Buyer and seller cannot be the same");
        require(bytes(_description).length > 0, "Description cannot be empty");
        
        uint256 transactionId = transactionCounter++;
        
        escrowTransactions[transactionId] = EscrowTransaction({
            buyer: msg.sender,
            seller: _seller,
            amount: msg.value,
            isCompleted: false,
            isDisputed: false,
            createdAt: block.timestamp,
            description: _description
        });
        
        emit EscrowCreated(
            transactionId,
            msg.sender,
            _seller,
            msg.value,
            _description
        );
        
        return transactionId;
    }
    
    /**
     * @dev Releases funds to the seller (called by buyer)
     * @param _transactionId ID of the transaction
     */
    function releaseFunds(uint256 _transactionId)
        external
        onlyBuyer(_transactionId)
        transactionExists(_transactionId)
        notCompleted(_transactionId)
        nonReentrant
    {
        EscrowTransaction storage transaction = escrowTransactions[_transactionId];
        require(!transaction.isDisputed, "Transaction is disputed");
        
        transaction.isCompleted = true;
        
        // Calculate service fee
        uint256 serviceFee = (transaction.amount * serviceFeeRate) / 10000;
        uint256 sellerAmount = transaction.amount - serviceFee;
        
        // Transfer funds to seller
        payable(transaction.seller).transfer(sellerAmount);
        
        // Transfer service fee to contract owner
        if (serviceFee > 0) {
            payable(owner()).transfer(serviceFee);
        }
        
        emit EscrowCompleted(
            _transactionId,
            transaction.buyer,
            transaction.seller,
            transaction.amount
        );
    }
    
    /**
     * @dev Initiates a dispute for the transaction
     * @param _transactionId ID of the transaction
     */
    function initiateDispute(uint256 _transactionId)
        external
        transactionExists(_transactionId)
        notCompleted(_transactionId)
    {
        EscrowTransaction storage transaction = escrowTransactions[_transactionId];
        require(
            msg.sender == transaction.buyer || msg.sender == transaction.seller,
            "Only buyer or seller can initiate dispute"
        );
        require(!transaction.isDisputed, "Transaction already disputed");
        
        transaction.isDisputed = true;
        
        emit EscrowDisputed(_transactionId, msg.sender);
    }
    
    /**
     * @dev Resolves a dispute (only owner can call)
     * @param _transactionId ID of the transaction
     * @param _releaseToBuyer If true, refunds to buyer; if false, releases to seller
     */
    function resolveDispute(
        uint256 _transactionId,
        bool _releaseToBuyer
    )
        external
        onlyOwner
        transactionExists(_transactionId)
        notCompleted(_transactionId)
        nonReentrant
    {
        EscrowTransaction storage transaction = escrowTransactions[_transactionId];
        require(transaction.isDisputed, "Transaction is not disputed");
        
        transaction.isCompleted = true;
        
        if (_releaseToBuyer) {
            // Refund to buyer
            payable(transaction.buyer).transfer(transaction.amount);
        } else {
            // Release to seller with service fee deduction
            uint256 serviceFee = (transaction.amount * serviceFeeRate) / 10000;
            uint256 sellerAmount = transaction.amount - serviceFee;
            
            payable(transaction.seller).transfer(sellerAmount);
            
            if (serviceFee > 0) {
                payable(owner()).transfer(serviceFee);
            }
        }
        
        emit EscrowCompleted(
            _transactionId,
            transaction.buyer,
            transaction.seller,
            transaction.amount
        );
    }
    
    /**
     * @dev Updates the service fee rate (only owner can call)
     * @param _newRate New service fee rate in basis points
     */
    function updateServiceFeeRate(uint256 _newRate) external onlyOwner {
        require(_newRate <= MAX_SERVICE_FEE_RATE, "Fee rate exceeds maximum");
        
        uint256 oldRate = serviceFeeRate;
        serviceFeeRate = _newRate;
        
        emit ServiceFeeUpdated(oldRate, _newRate);
    }
    
    /**
     * @dev Gets transaction details
     * @param _transactionId ID of the transaction
     * @return EscrowTransaction struct
     */
    function getTransaction(uint256 _transactionId)
        external
        view
        transactionExists(_transactionId)
        returns (EscrowTransaction memory)
    {
        return escrowTransactions[_transactionId];
    }
    
    /**
     * @dev Gets the total number of transactions
     * @return Total transaction count
     */
    function getTotalTransactions() external view returns (uint256) {
        return transactionCounter;
    }
    
    /**
     * @dev Emergency withdrawal function (only owner)
     */
    function emergencyWithdraw() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }
    
    /**
     * @dev Gets contract balance
     * @return Contract balance in wei
     */
    function getContractBalance() external view returns (uint256) {
        return address(this).balance;
    }
}

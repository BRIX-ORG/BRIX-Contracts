// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";

/**
 * @title BrixRegistry
 * @notice Unified on-chain registry for BRIX: IPFS fee payment, brick minting, and donations.
 * @dev Runs on Polygon L2. Optimized for low gas usage.
 *
 * Flows:
 *   1. payForIPFS  → user pays fee → event emitted → backend uploads to IPFS
 *   2. mint        → user creates on-chain brick (must have paid IPFS first)
 *   3. donate      → funds split between creator & platform → backend logs
 */
contract BrixRegistry is Ownable, ReentrancyGuard, Pausable {
    // ──────────────────── Custom Errors ────────────────────
    error InsufficientFee(uint256 required, uint256 sent);
    error AlreadyPaid();
    error AlreadyMinted();
    error InvalidBrickId();
    error InvalidCID();
    error NotPaidForIPFS();
    error ZeroDonation();
    error ZeroWithdrawal();
    error TransferFailed();
    error InvalidAddress();
    error InvalidPercentage();
    error InvalidFee();
    error NoStuckFunds();

    // ──────────────────── Constants ────────────────────
    uint256 public constant MAX_PLATFORM_FEE_PERCENT = 40;
    uint256 public constant MAX_IPFS_FEE = 10 ether;

    // ──────────────────── State ────────────────────
    struct Brick {
        address creator;
        string ipfsCid;
        uint256 totalDonated;
    }

    mapping(uint256 => Brick) public bricks;
    uint256 public brickCount;

    /// @notice Tracks which brickIds have already paid for IPFS (prevents MEV frontrunning)
    /// @dev Maps keccak256(abi.encodePacked(brickId, msg.sender)) => bool
    mapping(bytes32 => bool) public paidForIpfs;

    /// @notice Tracks which specific bricks have already been minted to prevent double-minting
    mapping(bytes32 => bool) public isMinted;

    /// @notice Pull-payment mapping for safe donation withdrawals (prevents blocking)
    mapping(address => uint256) public pendingWithdrawals;

    address public platformFeeAddress;
    uint256 public ipfsFee; // fee in wei for IPFS distribution
    uint256 public platformFeePercent = 10; // default 10%, max 40%

    /// @notice Accumulated IPFS fees available for owner withdrawal
    uint256 public collectedIpfsFees;

    /// @notice Total donations currently pending withdrawal (artist + platform)
    uint256 public totalPendingDonations;

    // ──────────────────── Events ────────────────────
    /// @notice Emitted when a user pays for IPFS distribution (no state stored)
    event PaidForIPFS(address indexed user, bytes32 brickId);

    /// @notice Emitted when a new brick is minted on-chain
    event BrickCreated(uint256 indexed id, address indexed creator, string ipfsCid);

    /// @notice Emitted when a donation is made to a brick
    event Donated(
        uint256 indexed brickId,
        address indexed donor,
        uint256 amount,
        uint256 artistAmount,
        uint256 platformAmount
    );

    /// @notice Emitted when IPFS fee is updated
    event IpfsFeeUpdated(uint256 oldFee, uint256 newFee);

    /// @notice Emitted when platform fee percent is updated
    event PlatformFeeUpdated(uint256 oldPercent, uint256 newPercent);

    /// @notice Emitted when platform fee address is updated
    event PlatformFeeAddressUpdated(address oldAddress, address newAddress);

    /// @notice Emitted when the owner withdraws accumulated IPFS fees
    event FeesWithdrawn(address owner, uint256 amount);

    /// @notice Emitted when a creator or platform withdraws their accumulated donations
    event DonationWithdrawn(address account, uint256 amount);

    /// @notice Emitted when the owner withdraws stuck funds
    event StuckFundsWithdrawn(address owner, uint256 amount);

    // ──────────────────── Constructor ────────────────────
    /**
     * @param _platformFeeAddress Address that receives the platform share of donations
     * @param _ipfsFee Initial fee (wei) users pay for IPFS distribution
     */
    constructor(address _platformFeeAddress, uint256 _ipfsFee) Ownable(msg.sender) {
        if (_platformFeeAddress == address(0)) revert InvalidAddress();
        platformFeeAddress = _platformFeeAddress;
        ipfsFee = _ipfsFee;
    }

    // ═══════════════════════════════════════════════════════
    //  FLOW 1 — payForIPFS
    // ═══════════════════════════════════════════════════════

    /**
     * @notice User pays the IPFS fee. Backend listens for the event and uploads to IPFS.
     * @param brickId The off-chain brick UUID representation (bytes32).
     * @dev Bound to the msg.sender to prevent MEV front-running.
     *      Fee is tracked separately and can be withdrawn by the owner.
     *      Excess ETH is refunded to the sender.
     */
    function payForIPFS(bytes32 brickId) external payable nonReentrant whenNotPaused {
        if (brickId == bytes32(0)) revert InvalidBrickId();
        if (msg.value < ipfsFee) revert InsufficientFee(ipfsFee, msg.value);

        bytes32 id = keccak256(abi.encodePacked(brickId, msg.sender));
        if (paidForIpfs[id]) revert AlreadyPaid();

        paidForIpfs[id] = true;
        collectedIpfsFees += ipfsFee; // Only track the actual fee

        // Refund excess ETH
        if (msg.value > ipfsFee) {
            (bool ok, ) = payable(msg.sender).call{ value: msg.value - ipfsFee }("");
            if (!ok) revert TransferFailed();
        }

        emit PaidForIPFS(msg.sender, brickId);
    }

    // ═══════════════════════════════════════════════════════
    //  FLOW 2 — Onchain Mint
    // ═══════════════════════════════════════════════════════

    /**
     * @notice Mint a brick on-chain after IPFS distribution is complete.
     * @param brickId The off-chain brick representation (bytes32) that was paid for.
     * @param ipfsCid The IPFS CID of the brick metadata
     * @dev Caller must have paid for IPFS for this specific brickId.
     *      Stores minimal data: creator address, ipfsCid, totalDonated (0).
     */
    function mint(bytes32 brickId, string calldata ipfsCid) external nonReentrant whenNotPaused {
        if (brickId == bytes32(0)) revert InvalidBrickId();
        if (bytes(ipfsCid).length == 0) revert InvalidCID();

        bytes32 paymentId = keccak256(abi.encodePacked(brickId, msg.sender));
        if (isMinted[paymentId]) revert AlreadyMinted();
        if (!paidForIpfs[paymentId]) revert NotPaidForIPFS();

        isMinted[paymentId] = true;
        delete paidForIpfs[paymentId]; // Free storage slot to refund gas

        uint256 id = ++brickCount;

        bricks[id] = Brick({ creator: msg.sender, ipfsCid: ipfsCid, totalDonated: 0 });

        emit BrickCreated(id, msg.sender, ipfsCid);
    }

    // ═══════════════════════════════════════════════════════
    //  FLOW 3 — Donate
    // ═══════════════════════════════════════════════════════

    /**
     * @notice Donate MATIC to a minted brick. Funds are split between the
     *         creator and the platform according to `platformFeePercent`.
     * @param brickId On-chain brick ID (sequential, starts at 1)
     * @dev Uses Pull-Payment pattern. Funds are accumulated in pendingWithdrawals
     *      to prevent blocking if the creator is a contract that cannot receive ETH.
     */
    function donate(uint256 brickId) external payable nonReentrant whenNotPaused {
        if (brickId == 0 || brickId > brickCount) revert InvalidBrickId();
        if (msg.value == 0) revert ZeroDonation();

        Brick storage brick = bricks[brickId];

        // Platform takes percent (truncates down). Artist gets the rest (keeps the 1 wei remainder if any).
        uint256 platformAmount = (msg.value * platformFeePercent) / 100;
        uint256 artistAmount = msg.value - platformAmount;

        brick.totalDonated += msg.value;

        // Pull-payment: add to pending withdrawals instead of tracking failures
        pendingWithdrawals[platformFeeAddress] += platformAmount;
        pendingWithdrawals[brick.creator] += artistAmount;
        totalPendingDonations += msg.value;

        emit Donated(brickId, msg.sender, msg.value, artistAmount, platformAmount);
    }

    /**
     * @notice Allows a user (artist or platform) to withdraw their accumulated donations.
     * @dev Safe pull-payment withdrawal function. Can be called even when paused to rescue funds.
     */
    function withdrawDonation() external nonReentrant {
        uint256 amount = pendingWithdrawals[msg.sender];
        if (amount == 0) revert ZeroWithdrawal();

        pendingWithdrawals[msg.sender] = 0;
        totalPendingDonations -= amount;

        (bool ok, ) = payable(msg.sender).call{ value: amount }("");
        if (!ok) revert TransferFailed();

        emit DonationWithdrawn(msg.sender, amount);
    }

    // ═══════════════════════════════════════════════════════
    //  Admin Functions
    // ═══════════════════════════════════════════════════════

    /**
     * @notice Update the IPFS distribution fee
     * @dev Capped at MAX_IPFS_FEE to prevent owner abuse
     */
    function setIpfsFee(uint256 _newFee) external onlyOwner {
        if (_newFee > MAX_IPFS_FEE) revert InvalidFee();
        uint256 oldFee = ipfsFee;
        ipfsFee = _newFee;
        emit IpfsFeeUpdated(oldFee, _newFee);
    }

    /**
     * @notice Update the platform fee percentage (0 to MAX_PLATFORM_FEE_PERCENT)
     * @dev Capped at 40% — platform can never take more than 40% of donations
     */
    function setPlatformFeePercent(uint256 _newPercent) external onlyOwner {
        if (_newPercent > MAX_PLATFORM_FEE_PERCENT) revert InvalidPercentage();
        uint256 oldPercent = platformFeePercent;
        platformFeePercent = _newPercent;
        emit PlatformFeeUpdated(oldPercent, _newPercent);
    }

    /**
     * @notice Update the platform fee address
     */
    function setPlatformFeeAddress(address _newAddress) external onlyOwner {
        if (_newAddress == address(0)) revert InvalidAddress();
        address oldAddress = platformFeeAddress;
        platformFeeAddress = _newAddress;
        emit PlatformFeeAddressUpdated(oldAddress, _newAddress);
    }

    /**
     * @notice Withdraw only accumulated IPFS fees (not donation funds)
     * @dev Only callable by the contract owner. Tracks fees separately for safety.
     */
    function withdrawIpfsFees() external onlyOwner {
        uint256 amount = collectedIpfsFees;
        if (amount == 0) revert ZeroWithdrawal();

        collectedIpfsFees = 0;

        (bool ok, ) = payable(msg.sender).call{ value: amount }("");
        if (!ok) revert TransferFailed();

        emit FeesWithdrawn(msg.sender, amount);
    }

    /**
     * @notice Emergency: withdraw ALL stuck funds (if bug causes funds to be trapped)
     * @dev Only withdraws balance that is not accounted for by pending donations and IPFS fees.
     */
    function withdrawStuckFunds() external onlyOwner {
        uint256 accountedFor = totalPendingDonations + collectedIpfsFees;
        uint256 balance = address(this).balance;

        if (balance <= accountedFor) revert NoStuckFunds();

        uint256 stuck = balance - accountedFor;

        (bool ok, ) = payable(msg.sender).call{ value: stuck }("");
        if (!ok) revert TransferFailed();

        emit StuckFundsWithdrawn(msg.sender, stuck);
    }

    /**
     * @notice Pause the contract (stops payForIPFS, mint, donate). Withdrawals still work.
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @notice Unpause the contract.
     */
    function unpause() external onlyOwner {
        _unpause();
    }

    /**
     * @notice Fallback to accept unstructured ETH transfers
     * @dev Any ETH sent here can be rescued via withdrawStuckFunds.
     *      No fallback() intentional: reject ETH sent via unknown function calls.
     */
    receive() external payable {}

    // ──────────────────── View Helpers ────────────────────

    /**
     * @notice Get brick details
     */
    function getBrick(
        uint256 brickId
    ) external view returns (address creator, string memory ipfsCid, uint256 totalDonated) {
        if (brickId == 0 || brickId > brickCount) revert InvalidBrickId();
        Brick storage b = bricks[brickId];
        return (b.creator, b.ipfsCid, b.totalDonated);
    }

    /**
     * @notice Check if a specific address has paid for a specific brickId
     * @dev Returns false if the user has already minted (paidForIpfs is deleted post-mint).
     *      Use hasMinted() to check mint status separately.
     */
    function hasPaid(bytes32 brickId, address user) external view returns (bool) {
        return paidForIpfs[keccak256(abi.encodePacked(brickId, user))];
    }

    /**
     * @notice Check if a brickId has already been minted by a specific user
     */
    function hasMinted(bytes32 brickId, address user) external view returns (bool) {
        return isMinted[keccak256(abi.encodePacked(brickId, user))];
    }
}

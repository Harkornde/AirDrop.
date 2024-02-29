//SPDX-License-Identifier: MIT
pragma solidity ^0.8;

// Import the ERC-20 token standard interface
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@chainlink/contracts/src/v0.8/vendor/SafeMathChainlink.sol";

// Define the PrizePool contract
contract Airdrop {
    using SafeMathChainlink for uint256;

    // Define the variables
    address public owner; // The owner of the contract
    IERC20 public token; // The ERC-20 token to be distributed as rewards
    AggregatorV3Interface public vrf; // The Chainlink VRF contract
    uint256 public fee; // The fee to pay for the VRF request
    bytes32 public keyHash; // The key hash for the VRF request
    uint256 public randomness; // The random number returned by the VRF
    uint256 public totalParticipants; // The total number of participants in the game or activity
    uint256 public totalRewards; // The total amount of tokens to be distributed as rewards
    uint256 public rewardPerParticipant; // The amount of tokens to be rewarded to each participant
    mapping(address => bool) public participants; // A mapping of participants' addresses to their participation status
    mapping(bytes32 => address) public requestIdToSender; // A mapping of VRF request IDs to the sender's address

    // Define the events
    event Participated(address indexed participant); // Emitted when a participant joins the game or activity
    event RequestedRandomness(bytes32 indexed requestId); // Emitted when a VRF request is sent
    event ReceivedRandomness(bytes32 indexed requestId, uint256 indexed randomness); // Emitted when a VRF response is received
    event Rewarded(address indexed participant, uint256 indexed amount); // Emitted when a participant receives their reward

    // Define the constructor
    constructor(
        address _token, // The address of the ERC-20 token
        address _vrf, // The address of the Chainlink VRF contract
        uint256 _fee, // The fee to pay for the VRF request
        bytes32 _keyHash // The key hash for the VRF request
    ) {
        owner = msg.sender; // Set the owner as the deployer of the contract
        token = IERC20(_token); // Set the token as the ERC-20 token
        vrf = AggregatorV3Interface(_vrf); // Set the vrf as the Chainlink VRF contract
        fee = _fee; // Set the fee as the fee to pay for the VRF request
        keyHash = _keyHash; // Set the keyHash as the key hash for the VRF request
    }

    // Define a modifier to check if the caller is the owner
    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can call this function");
        _;
    }

    // Define a function to participate in the game or activity
    function participate() external {
        require(!participants[msg.sender], "You have already participated"); // Check if the caller has already participated
        participants[msg.sender] = true; // Mark the caller as a participant
        totalParticipants = totalParticipants.add(1); // Increment the total number of participants
        emit Participated(msg.sender); // Emit the Participated event
    }

    // Define a function to request a random number from the VRF
    function requestRandomness() external onlyOwner {
        require(totalParticipants > 0, "There are no participants"); // Check if there are any participants
        require(totalRewards > 0, "There are no rewards"); // Check if there are any rewards
        require(token.balanceOf(address(this)) >= totalRewards, "Insufficient token balance"); // Check if the contract has enough tokens
        require(LINK.balanceOf(address(this)) >= fee, "Insufficient LINK balance"); // Check if the contract has enough LINK
        bytes32 requestId = vrf.requestRandomness(keyHash, fee); // Send a VRF request and get the request ID
        requestIdToSender[requestId] = msg.sender; // Map the request ID to the sender's address
        emit RequestedRandomness(requestId); // Emit the RequestedRandomness event
    }

    // Define a function to receive a random number from the VRF
    function fulfillRandomness(bytes32 requestId, uint256 randomness) external {
        require(msg.sender == address(vrf), "Only the VRF can call this function"); // Check if the caller is the VRF contract
        require(requestIdToSender[requestId] == owner, "Invalid request ID"); // Check if the request ID is valid
        randomness = randomness; // Set the randomness as the random number returned by the VRF
        emit ReceivedRandomness(requestId, randomness); // Emit the ReceivedRandomness event
        distributeRewards(); // Call the distributeRewards function
    }

    // Define a function to distribute rewards to the participants
    function distributeRewards() internal {
        rewardPerParticipant = totalRewards.div(totalParticipants); // Calculate the reward per participant
        for (uint256 i = 0; i < totalParticipants; i++) {
            address participant = address(uint160(uint256(keccak256(abi.encode(randomness, i))))); // Generate a pseudo-random address from the randomness and the index
            require(participants[participant], "Invalid participant"); // Check if the address is a valid participant
            token.transfer(participant, rewardPerParticipant); // Transfer the reward to the participant
            emit Rewarded(participant, rewardPerParticipant); // Emit the Rewarded event
        }
    }

    // Define a function to set the total amount of rewards
    function setTotalRewards(uint256 _totalRewards) external onlyOwner {
        totalRewards = _totalRewards; // Set the totalRewards as the input value
    }

    // Define a function to withdraw any remaining tokens or LINK from the contract
    function withdraw(address _token, uint256 _amount) external onlyOwner {
        IERC20(_token).transfer(owner, _amount); // Transfer the token or LINK to the owner
    }
}

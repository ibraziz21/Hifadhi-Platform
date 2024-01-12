// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.20;

/* VunaVault Is a product of the hifadhi platform
    It is a target-based savings module where the user can
    Set a goal, e.g. Buy a House
    Set target price of the goal, e.g. $5000
    Set their monthly saving target, e.g. $50
    The smart contract will be responsible for holding the savings
    and tracking the payment patterns.
    The saved amount will be in stablecoins to ensure no value loss. 

    On creation of the saving goal, the user will be charged a small fee

*/
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract VunaVault  is Ownable{
    error InvalidInput();
    error NotEnoughForFees();
    error PoolNotFound();
    error InsufficientFunds();
    error PoolNotActive();

    event TargetSavingsCreated(address user,  uint256 target, uint256 contribution, uint256 duration);


    IERC20 token;
    address _feeCollector;
    uint256 fee;

    struct SavingGoals {
        uint256 targetSavings;
        uint256 contributionPerTurn;
        uint256 durationPerTurn;
        uint256 totalcontributed;
        bool isActive;
        bool isTargetReached;

        
    }
    mapping (address => mapping(uint256 =>SavingGoals)) private userPool;
    mapping (address => uint) public userGoalCount;

    constructor(address _usableToken, address feeVault, uint256 _fee) Ownable(msg.sender) {
        if(_usableToken == address(0) || feeVault == address(0) || _fee == 0) revert InvalidInput();
        token = IERC20(_usableToken);
        _feeCollector = feeVault;
        fee = _fee;
    }

    modifier validPoolID (uint256 targetID) {
         if(targetID> countPools(msg.sender)) revert PoolNotFound();
         _;
    }

    // User creates the target
    function createTarget( uint256 _target, uint256 _contributionPerTurn, uint256 _duration) external {
        uint256 count = countPools(msg.sender);
        userGoalCount[msg.sender] = ++count;


        //inputValidation
        if(_target == 0 || _contributionPerTurn>_target || _duration==0) revert InvalidInput();
        //Ensure the user has enough to cover the fee
        if(token.balanceOf(msg.sender) < fee) revert NotEnoughForFees();

        //token Approval
        if (token.allowance(msg.sender, address(this)) < fee) {
            bool approvalSuccess = token.approve(address(this), fee);
            require(approvalSuccess, "Token approval failed");
        }

        token.transferFrom(msg.sender, _feeCollector, fee);

        SavingGoals storage setDetails = userPool[msg.sender][count];
        setDetails.targetSavings = _target;
        setDetails.contributionPerTurn = _contributionPerTurn;
        setDetails.durationPerTurn = _duration;
        setDetails.isActive = true;

        emit TargetSavingsCreated(msg.sender, _target, _contributionPerTurn, _duration);
    }  

    function contribute(uint256 targetID) external validPoolID(targetID) {
       // uint256 userSavingsPools = countPools(msg.sender);
      //  if(targetID> userSavingsPools) revert PoolNotFound();

        uint256 contributionAmount = userPool[msg.sender][targetID].contributionPerTurn;
        if(token.balanceOf(msg.sender) < contributionAmount) revert InsufficientFunds();

        //token Approval
        if (token.allowance(msg.sender, address(this)) < contributionAmount) {
            bool approvalSuccess = token.approve(address(this), contributionAmount);
            require(approvalSuccess, "Token approval failed");
        }

        token.transferFrom(msg.sender, address(this), contributionAmount);

        userPool[msg.sender][targetID].totalcontributed+=contributionAmount;
        
    }

    function WithdrawSavings(uint256 targetID) external validPoolID(targetID){
        //function to claim saved amount
        SavingGoals storage withdrawDetails = userPool[msg.sender][targetID];

        if(withdrawDetails.isActive == false) revert PoolNotActive();


        uint256 totalSaved = withdrawDetails.totalcontributed;
        uint256 remainingAmount = checkRemainingAmount(msg.sender, targetID);
        if(remainingAmount == 0) {
            withdrawDetails.isTargetReached = true;
        }else {
            withdrawDetails.isTargetReached = false;
        }
        withdrawDetails.isActive = false;

        token.transferFrom(address(this), msg.sender, totalSaved);
        
        
    }


    function countPools(address _user) public view returns(uint256){
            return userGoalCount[_user];
    }

    function checkRemainingAmount(address _user, uint256 targetID) public view returns(uint256) {
        uint256 targetAmt = userPool[_user][targetID].targetSavings;
        uint256 totalSaved = userPool[_user][targetID].totalcontributed;

        return targetAmt - totalSaved;
    }

   
        
    }


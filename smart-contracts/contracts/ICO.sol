// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";


contract StknICO {
    //Administration Details
    address public admin;
    address payable public ICOWallet;

    //Token
    IERC20 public token;

    //ICO Details
    uint256 public tokenPrice = 0.000001 ether;
    uint256 public hardCap = 0.001 ether;
    uint256 public softCap = 0.0001 ether;
    uint public raisedAmount;
    uint256 public minInvestment = 0.00001 ether;
    uint256 public maxInvestment = 0.00005 ether;
    uint public icoStartTime;
    uint public icoEndTime;

    //Investor
    mapping(address => uint) public investedAmountOf;

    //ICO State
    enum State {
        BEFORE,
        RUNNING,
        Fail,
        Success
    }
    State public ICOState;

    //Events
    event Invest(
        address indexed from,
        address indexed to,
        uint value,
        uint tokens
    );
    event Withdrawl(address from, address to, uint value);
    event Claim(address from, address to, uint value);
    event End(string ICOresult);
    //Initialize Variables
    constructor(address payable _icoWallet, address _token) {
        admin = msg.sender;
        ICOWallet = _icoWallet;
        token = IERC20(_token);
    }
    //Access Control
    modifier onlyAdmin() {
        require(msg.sender == admin, "Admin Only function");
        _;
    }

    //Receive Ether Directly
    receive() external payable {
        invest();
    }

    fallback() external payable {
        invest();
    }

    /* Functions */

    //Get ICO State
    function getICOState() external view returns (string memory) {
        if (ICOState == State.BEFORE) {
            return "Not Started";
        } else if (ICOState == State.RUNNING) {
            return "Running";
        } else if (ICOState == State.Fail) {
            return "Fail";
        } else {
            return "Success";
        }
    }

    /* Admin Functions */

    //Start, Halt and End ICO
    function startICO() external onlyAdmin {
        require(ICOState == State.BEFORE, "ICO isn't in before state");

        icoStartTime = block.timestamp;
        icoEndTime = icoStartTime + 24 * 60 * 60;
        ICOState = State.RUNNING;
    }

    // //Change ICO Wallet
    // function changeICOWallet(address payable _newICOWallet) external onlyAdmin {
    //     ICOWallet = _newICOWallet;
    // }

    // //Change Admin
    // function changeAdmin(address _newAdmin) external onlyAdmin {
    //     admin = _newAdmin;
    // }

    /* User Function */
    
    //Invest
    function invest() public payable returns (bool) {
        uint256 x = msg.value;
        require(ICOState == State.RUNNING, "ICO isn't running");
        require(
            x >= minInvestment && x <= maxInvestment,
            "Check Min and Max Investment"
        );
        require(
            raisedAmount + msg.value <= hardCap,
            "Send within hardcap range"
        );
        require(
            block.timestamp <= icoEndTime,
            "ICO already Reached Maximum time limit"
        );

        raisedAmount += msg.value;
        investedAmountOf[msg.sender] += msg.value;

        (bool transferSuccess, ) = ICOWallet.call{value: msg.value}("");
        require(transferSuccess, "Failed to Invest");

        uint tokens = (msg.value / tokenPrice) * 1e18;
        emit Invest(address(this), msg.sender, msg.value, tokens);
        return true;
    }

    //Burn Tokens
    function withdrawl() external returns (bool) {
        require(ICOState == State.Fail, "ICO isn't failed");
        uint amountToSend = investedAmountOf[msg.sender];
        investedAmountOf[msg.sender] = 0;
        payable(msg.sender).transfer(amountToSend);
        emit Withdrawl(address(this), msg.sender, amountToSend );
        return true;
    }
    function claim() external returns (bool) {
        require(ICOState == State.Success, "ICO isn't successed");
        uint amountToSend = investedAmountOf[msg.sender];
        investedAmountOf[msg.sender] = 0;
        uint tokens = (amountToSend / tokenPrice) * 1e18;
        bool saleSuccess = token.transfer(msg.sender, tokens);
        require(saleSuccess, "Failed to Invest");
        emit Claim(address(this), msg.sender, tokens );
        return true;
    }
    //End ICO After reaching Hardcap or ICO Timelimit
    function endIco() public {
        require(ICOState == State.RUNNING, "ICO Should be in Running State");
        require(
            block.timestamp > icoEndTime || raisedAmount >= hardCap,
            "ICO Hardcap or timelimit not reached"
        );
        if (block.timestamp > icoEndTime && raisedAmount < softCap){
            ICOState = State.Fail;
            emit End("Fail");
        }
        else {
            ICOState = State.Success;
            emit End("Success");
        }

    }

    //Check ICO Contract Token Balance
    function getICOTokenBalance() external view returns (uint) {
        return token.balanceOf(address(this));
    }

    //Check ICO Contract Investor Token Balance
    function investorBalanceOf(address _investor) external view returns (uint) {
        return token.balanceOf(_investor);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@uniswap/v3-core/contracts/interfaces/callback/IUniswapV3SwapCallback.sol";
import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";

interface ISwapRouter is IUniswapV3SwapCallback, IUniswapV2Router02 {
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactInputSingleParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInputSingle(ExactInputSingleParams calldata params) external payable returns (uint256 amountOut);

    struct ExactInputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another along the specified path
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactInputParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInput(ExactInputParams calldata params) external payable returns (uint256 amountOut);

    struct ExactOutputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactOutputSingleParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutputSingle(ExactOutputSingleParams calldata params) external payable returns (uint256 amountIn);

    struct ExactOutputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another along the specified path (reversed)
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactOutputParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutput(ExactOutputParams calldata params) external payable returns (uint256 amountIn);
}

contract duetBuyRouter is Ownable, Pausable, ReentrancyGuard{

    using SafeMath for uint256;
    IERC20 public USDT;
    IERC20 public maticToken;

    IUniswapV2Router02 public sushiRouter;
    ISwapRouter public uniRouter1;
    IUniswapV2Pair public sushiPair1;
    IUniswapV3Pool public uniPair2;
    IUniswapV2Factory public sushiFactory;
    IUniswapV2Factory public uniFactory;
    address public LpReceiver;
    address public WETH;
    uint256 public PoolBNBamount;
    uint256 public PoolTokenamount;
    uint256 public PoolPercentage = 50;
    uint256 public SWAPTokenPercentage = 25;
    uint256 public tokenCount;
    uint256 public maticCount;
    uint256 HalfToken;
    uint256 ContractBalance;
    uint256 public returnUSDTToken;
    bool public switched;
                    
    event percentageUpdated(address indexed _owner, uint256 indexed _percentageSet);
    event stateSwitched(address indexed _owner, bool indexed sateSet);
    event maticWithdrawed(address indexed _owner, uint256 indexed _amount);
    event pairAddress1Set(address indexed _owner, address indexed pairAddress_);
    event pairAddress2Set(address indexed _owner, address indexed pairAddress_);
    event USDTWithdrawed(address indexed _owner, uint256 indexed _amount);
    event _tokenArbitrage(address indexed _user, uint256 indexed _enteredAmount, uint256 indexed _userProfit);
    event _maticarbitrage(address indexed _user, uint256 indexed _paidAmount, uint256 indexed _userProfit);
    event isPaused(address indexed _owner, bool indexed paused);

    /*
    => all addresses will be set here in the constructor
    => these addresses can be change after that
    */ 
    constructor()
    {
       USDT = IERC20(0xc2132D05D31c914a87C6611C10748AEb04B58e8F);

       maticToken = IERC20(0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270);

       sushiRouter = IUniswapV2Router02(0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506);  // sushiswap
       uniRouter1 = ISwapRouter(0xE592427A0AEce92De3Edee1F18E0157C05861564);  // uniswap v3
        //    LpReceiver = 0xf6f2Bd97D33EAB1cFa78028d4e518823B9158430;
       sushiPair1 = IUniswapV2Pair(0x55FF76BFFC3Cdd9D5FdbBC2ece4528ECcE45047e);
       uniPair2 = IUniswapV3Pool(0x9B08288C3Be4F62bbf8d1C20Ac9C5e6f9467d8B7);
        //    USDTReceiver = 0xB4E9A91c810d4e3feF0b4f336f41E6F470e098da;
    }

    /*
    => EOA have to pay for this function
    => EOA can call this function
    => contract fee will deduct in every transaction
    => first contract will get reserves from swaps
    => then compare them
    => swap from less and sell to high liquidity swap
    => contract deduct the fee from user's profit
    */

    function maticArbitrage() public 
    payable
    nonReentrant
    {
        require(msg.sender == tx.origin," External Error ");
        require(msg.value > 0 ,"Amount must be greater than zero!!");
        require(switched, "currently this function is not available!!");
        uint256 maticAmount = msg.value;
        uint256 profit;
        uint256 userProfit;
        uint256 contractFee;

        address[] memory path = new address[](2);
        path[0] = address(maticToken);
        path[1] = address(USDT);

        uint256[] memory returnValues1 = uniRouter1.getAmountsOut(maticAmount,path);
        uint256[] memory returnValues2 = sushiRouter.getAmountsOut(maticAmount,path);
        uint256 value1 = returnValues1[1];
        uint256 value2 = returnValues2[1];
        if(value2 > value1)
        {
            maticToken.approve(address(sushiRouter), maticAmount);
            uint256[] memory USDTAmounts1 = swapSushiExactMaticForUSDTtokens1(maticAmount);
            USDT.approve(address(uniRouter1), USDTAmounts1[1]);
            uint256[] memory maticAmounts1 = swapUniUSDTtokensForMatic1(USDTAmounts1[1]);
            profit = maticAmounts1[1].sub(maticAmount);
            contractFee = (profit.mul(SWAPTokenPercentage)).div(100);
            userProfit = profit.sub(contractFee);
            payable(msg.sender).transfer(userProfit);
        }
        else
        {
            maticToken.approve(address(uniRouter1), maticAmount);
            uint256[] memory USDTAmounts2 = swapUniExactMaticForUSDTtokens2(maticAmount);
            USDT.approve(address(sushiRouter), USDTAmounts2[1]);
            uint256[] memory maticAmounts2 = swapSushiUSDTtokensForMatic2(USDTAmounts2[1]);
            profit = maticAmounts2[1].sub(maticAmount);
            contractFee = (profit.mul(SWAPTokenPercentage)).div(100);
            userProfit = profit.sub(contractFee);
            payable(msg.sender).transfer(userProfit);
        }
        emit _maticarbitrage(msg.sender, maticAmount, userProfit);
    }

    /*
    => EOA must have to pay tokens fro this arbitrage
    => EOA can call this function
    => contract fee will deduct in every transaction
    => first contract will get reserves from swaps
    => then compare them
    => swap from less and sell to high liquidity swap
    => contract deduct the fee from user's profit
    */

    function tokenArbitrage(uint256 _tokenAmount) public 
    nonReentrant
    {
        require(msg.sender == tx.origin," External Error ");
        require(USDT.transferFrom(_msgSender(),address(this),_tokenAmount)," Approve ULE First ");
        require(!switched, "currently this function is not available!!");
        uint256 profit;
        uint256 userProfit;
        uint256 contractFee;

        address[] memory path = new address[](2);
        path[0] = address(USDT);
        path[1] = address(maticToken);

        uint256[] memory returnValues1 = uniRouter1.getAmountsOut(_tokenAmount,path);
        uint256[] memory returnValues2 = sushiRouter.getAmountsOut(_tokenAmount,path);
        uint256 value1 = returnValues1[1];
        uint256 value2 = returnValues2[1];
        if(value2 > value1)
        {
            maticToken.approve(address(sushiRouter), _tokenAmount);
            uint256[] memory USDTAmounts1 = swapSushiUSDTtokensForMatic2(_tokenAmount);
            USDT.approve(address(uniRouter1), USDTAmounts1[1]);
            uint256[] memory maticAmounts1 = swapUniExactMaticForUSDTtokens2(USDTAmounts1[1]);
            profit = maticAmounts1[1].sub(_tokenAmount);
            contractFee = (profit.mul(SWAPTokenPercentage)).div(100);
            userProfit = profit.sub(contractFee);
            USDT.transfer(msg.sender, userProfit);
        }
        else
        {
            maticToken.approve(address(uniRouter1), _tokenAmount);
            uint256[] memory USDTAmounts2 = swapUniUSDTtokensForMatic1(_tokenAmount);
            USDT.approve(address(sushiRouter), USDTAmounts2[1]);
            uint256[] memory maticAmounts2 = swapSushiExactMaticForUSDTtokens1(USDTAmounts2[1]);
            profit = maticAmounts2[1].sub(_tokenAmount);
            contractFee = (profit.mul(SWAPTokenPercentage)).div(100);
            userProfit = profit.sub(contractFee);
            USDT.transfer(msg.sender, userProfit);
        }

        emit _tokenArbitrage(msg.sender, _tokenAmount, userProfit);
    }


    function swapSushiExactMaticForUSDTtokens1(uint256 value) private
    returns(uint[] memory amounts)  
    {
        address[] memory path = new address[](2);
        path[0] = address(maticToken);
        path[1] = address(USDT);
        return sushiRouter.swapExactETHForTokens{value:value}(
        0, 
        path,
        address(this), 
        block.timestamp
        );
    }
    function swapUniUSDTtokensForMatic1(uint256 tokenAmount) private 
    returns(uint[] memory amounts){
        address[] memory path = new address[](2);
        path[0] = address(USDT);
        path[1] = address(maticToken);
        return uniRouter1.swapExactTokensForETH(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }
    function swapUniExactMaticForUSDTtokens2(uint256 value) private
     returns(uint[] memory amounts)  
    {
        address[] memory path = new address[](2);
        path[0] = address(maticToken);
        path[1] = address(USDT);
        return uniRouter1.swapExactETHForTokens{value:value}(
        0, 
        path,
        address(this), 
        block.timestamp
        );
    }
    function swapSushiUSDTtokensForMatic2(uint256 tokenAmount) private 
    returns(uint[] memory amounts){
        address[] memory path = new address[](2);
        path[0] = address(USDT);
        path[1] = address(maticToken);
        return sushiRouter.swapExactTokensForETH(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }
    function addLiquiditys1(uint256 _amount,uint256 half) public payable
    {
        sushiRouter.addLiquidityETH{value:half}(
            address(USDT),
            _amount,
            0,
            0,
            LpReceiver,
            block.timestamp
        );
    }
    function addLiquiditys2(uint256 _amount,uint256 half) public payable
    {
        uniRouter1.addLiquidityETH{value:half}(
            address(USDT),
            _amount,
            0,
            0,
            LpReceiver,
            block.timestamp
        );
    }
    /**
    =============    Owner Fucnitons  ==========
    => owner can:
    => withdraw USDTs from contract
    => withdraw matics from contract
    => set Pair addresses
    => set router addresses
    => set token addresses
    => pause/unpause the contarct
    => set the percentage
    => change the conditions fro arbitrage
    */
    function withdrawUSDTTtoken()
    public
    onlyOwner
    {   
        USDT.transfer(owner(),withdrawableUSDTtoken());   
        emit USDTWithdrawed(msg.sender, withdrawableUSDTtoken());
    }

    function withdrawableUSDTtoken()
    private
    view returns(uint256 amount)
    {
        amount = USDT.balanceOf(address(this));
        return amount;
    }

    function setPairAddress1(address _address) public onlyOwner{
        sushiPair1 = IUniswapV2Pair(_address);
        emit pairAddress1Set(msg.sender, _address);
    }
    
    function setPairAddress2(address _address) public onlyOwner{
        uniPair2 = IUniswapV3Pool(_address);
        emit pairAddress2Set(msg.sender, _address);
    }
    
    function updateSushiRouter(address _address) external onlyOwner{
        sushiRouter = IUniswapV2Router02(_address);
    }

    function updateUniRouter(address _address) external onlyOwner{
        uniRouter1 = ISwapRouter(_address);
    }

    function updateUSDTAddress(address _address) external onlyOwner{
        USDT = IERC20(_address);
    }
    function updateMaticAddress(address _address) external onlyOwner{
        maticToken = IERC20(_address);
    }


    function withdrawMATIC()
    public
    onlyOwner()
    {
        payable(msg.sender).transfer(address(this).balance);
        emit maticWithdrawed(msg.sender, address(this).balance);
    }

    function Switch() public onlyOwner(){
        if(!switched){  switched = true;    }
        else{  switched = false;    }
        emit stateSwitched(msg.sender, switched);
    }

    function percentage(uint256 _tokenAmount) public view returns(uint256 _amount){
        _amount = (_tokenAmount.mul(SWAPTokenPercentage)).div(100);
    }

    function updatePercentage(uint256 percentageAmount) external onlyOwner{
        SWAPTokenPercentage = percentageAmount;
        emit percentageUpdated(msg.sender, percentageAmount);
    }


    function pause() external onlyOwner{
        _pause();
        emit isPaused(msg.sender, true);
    }

    function unPaused() external onlyOwner{
        _unpause();
        emit isPaused(msg.sender, false);
    }
}
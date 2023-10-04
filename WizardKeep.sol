// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


contract WizardKeep{

    uint256 public _keepcount;
    uint256 public _usedETHBalance;
    address payable owner;

    //Details of the Game Created
    struct _GameDetails{
        uint256 gamesize;
        uint256 createtime;
        address createdby;
        uint256 start;
        uint256 over;
        uint256 _balance;
    }

    //Dertails of the Stake Holder for a particular game along with staking amount
    struct _stakeDetails{
        address _stakeholder;
        uint256 _amount;
        uint256 _winamount;
        uint256 _lossamount;
        uint256 _staketime;
        uint256 _chosenvault;
        bool Withdrawn;
    }

    mapping(uint256=>_GameDetails) public GameDetails;

    mapping(uint256=>mapping(address=>_stakeDetails)) public StakeDetails;

    mapping(uint256=>uint256) public TotalStaked;

    event CreateGameEV(uint256 indexed _gameid,uint256 indexed _gamesize,address indexed _creator,uint256 time);
    event DepositeEthEV(address indexed owner,address indexed to, uint256 indexed amount,uint256 time);
    event WithdrawEthEV(address indexed from,address indexed to, uint256 indexed amount,uint256 time);
    event StakeEV(address indexed owner,uint256 indexed amount,uint256 indexed game,uint256 time);
    event ChooseVaultEV(address indexed owner,uint256 indexed game,uint256 indexed boss,uint256 time);
    event UnstakeEV(address indexed owner,uint256 indexed game,uint256 indexed amount,uint256 time);

    constructor(){
        _keepcount=1;
        _usedETHBalance=0;
        owner=payable(msg.sender);
    }

    function DepositeETH() payable public {
        // nothing to do!
        emit DepositeEthEV(msg.sender,address(this),msg.value,block.timestamp);
    }

    function WithdrawETH() external payable returns(bool){
        require(msg.sender==owner,"Only Owner Can Withdraw From Contract");
        owner.transfer(address(this).balance);
        emit WithdrawEthEV(address(this),owner,address(this).balance,block.timestamp);
        return true;
    }

    function GetETHBalance() public view returns(uint256){
        return address(this).balance;
    }

    //Create Game By Owner By Putting GameSize like 1ETH=1e18)
    function CreateGame(uint256 gamesize) external returns(bool){
        require(owner==msg.sender,"Only Owner Can Create A Game");
        require(gamesize<=address(this).balance-_usedETHBalance,"Insufficient Balance To Create Game");
        _usedETHBalance+=gamesize;

        GameDetails[_keepcount]=_GameDetails(gamesize,block.timestamp,msg.sender,0,0,0);

        emit CreateGameEV(_keepcount,gamesize,msg.sender,block.timestamp);

        _keepcount++;
        return true;
    }

    // Players will Call this function with Game ID to stake the Amount;
    function Stake(uint256 _Gameid) external payable returns(bool){
        require(msg.value>0,"Staking Amount Cannot Be 0");
        require(GameDetails[_Gameid].start==0,"Game Already Started");
        require(TotalStaked[_Gameid]+msg.value<=GameDetails[_Gameid].gamesize,"Invalid staking Amount");

        StakeDetails[_Gameid][msg.sender]=_stakeDetails(msg.sender,msg.value,0,0,block.timestamp,0,false);
        TotalStaked[_Gameid]+=msg.value;

        if(TotalStaked[_Gameid]==GameDetails[_Gameid].gamesize)
        {
            GameDetails[_Gameid].start=1;
        }
        emit StakeEV(msg.sender,msg.value,_Gameid,block.timestamp);
        return true;
    }

    //Players will call this function and choose the Boss/Vault For game;
    function ChooseVault(uint256 _Gameid) external returns(bool)
    {
        require(GameDetails[_Gameid].start==1,"Game Has Not Started Yet");
        require(StakeDetails[_Gameid][msg.sender]._stakeholder==msg.sender,"U Cannot Choose Vault");
        require(StakeDetails[_Gameid][msg.sender]._chosenvault==0,"U Have Already Choosen Vault");

        uint token=random();
        uint256 stakeamt=StakeDetails[_Gameid][msg.sender]._amount;
        if(token>=0 && token<=25)
        {
            token=1;
            StakeDetails[_Gameid][msg.sender]._winamount=calculatewinamount(50,stakeamt);
            
        }
        else if(token>=26 && token<=50)
        {
            token=2;
             StakeDetails[_Gameid][msg.sender]._winamount=calculatewinamount(30,stakeamt);
        }
        else if(token>=51 && token<=75)
        {
            token=3;
             StakeDetails[_Gameid][msg.sender]._winamount=calculatewinamount(20,stakeamt);
        }
        else
        {
            token=4;
             StakeDetails[_Gameid][msg.sender]._lossamount=calculatewinamount(10,stakeamt);
             
        }

        StakeDetails[_Gameid][msg.sender]._chosenvault=token;
        emit ChooseVaultEV(msg.sender,_Gameid,token,block.timestamp);
        return true;
    }

    function unstakeFromGame(uint256 _Gameid) external returns(bool){
        require(StakeDetails[_Gameid][msg.sender].Withdrawn==false,"Nothing To Unstake");
        require(StakeDetails[_Gameid][msg.sender]._chosenvault!=0,"Please Choose Vault First");
        uint256 totalamt=StakeDetails[_Gameid][msg.sender]._amount+StakeDetails[_Gameid][msg.sender]._winamount-StakeDetails[_Gameid][msg.sender]._lossamount;
        payable(msg.sender).transfer(totalamt);
        emit UnstakeEV(msg.sender,_Gameid,totalamt,block.timestamp);
        return true;
    }

    function calculatewinamount(uint256 perc,uint256 stkamt) internal pure returns(uint256){
        return (stkamt*perc)/100;
    }

    function random() internal view returns(uint){
        return (uint(keccak256(abi.encodePacked(block.timestamp,block.difficulty, 
        msg.sender))) % 100);
    }
}
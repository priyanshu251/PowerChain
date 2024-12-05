// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Double-sidedAuction.sol";

contract PeerEnergy is DoubleSidedAuction {
    
    uint256 ithTime=24;
    uint256 InitialTime;
	
	struct Grid {
        uint256 totalProduction; 
		uint256 totalConsumption;
		uint256 StartTime;
		uint256 priceType;
        uint[] EngyMktConsensus;	
		address[] usrs;				
        uint256 ResetTime;
        uint[][] ESp; 				
        uint[][] ESq;				
        address[][] ESaddr; 		
        uint[][] EBp; 				
        uint[][] EBq; 				
        address[][] EBaddr;			
        uint256 utilitySellPrice;
	    uint256 utilityBuyPrice;
	    address [][] matchedBuyer;
	    address [][] matchedSeller;
	    uint256 [][] soldQuantity;
	    uint256 [][] soldPrice;
        uint256 []matchedLength; 
	}

	
	modifier AskEnergyRequirements (uint256 _price){
	    require(users[userAddresstoID[AppToSmartmeter[msg.sender]]].typeOfUser==2 && 
		_price<grids[gridIDToNo[users[userAddresstoID[AppToSmartmeter[msg.sender]]].gridNo]].utilitySellPrice,
		"Not a Prosumer or Price not within the range");
	    _;
	}

	
	modifier BidEnergyRequirements (uint256 _qty, uint256 _price){
		uint256 amt= _qty*_price*Token_rate*3600;
	    require(Checkbalance(AppToSmartmeter[msg.sender])>=amt && _price>grids[gridIDToNo[users[userAddresstoID[AppToSmartmeter[msg.sender]]].gridNo]].utilityBuyPrice, "Not enough balance or Price not within the range");
	    _;
	}

	
	modifier CheckIfUserExist(address _userSMAddr, address _userAppAddr){
	   require(_userSMAddr != AppToSmartmeter[_userAppAddr] && _userSMAddr != _userAppAddr && _userSMAddr != Utility && _userAppAddr != Utility, "User Already Exist");
	   _;
	}

	modifier CheckIfUserdoesntExist(address _SMtMeter, address _UseApp){
	   require(_SMtMeter==AppToSmartmeter[_UseApp],"User Does not Exist");
	   _;
	}


	modifier CheckIfGridExist(uint256 gridNM){
	   require(gridNoToID[gridIDToNo[gridNM]]!=gridNM,"Grid Already Exist");
	   _;
	}
	modifier CheckIfGridDoesntExist(uint256 gridNM){
	   require(gridNoToID[gridIDToNo[gridNM]]==gridNM,"Grid Does Not Exist");
	   _;
	}
	Grid[] public grids; 
	uint256 public Token_rate= 1;
	                          

	uint256 userBalTime=(1440/ithTime);
	uint256 public gridbalancetime=userBalTime;


	mapping (uint256 => uint) public gridNoToID;	
    mapping (uint256 => uint) public gridIDToNo;	
						

    mapping (address => uint) public userIDtoAddrInMG; 


	
	function createUser(address SmartmeterAddr,address AppNodeAddr, uint256 _typeOfUser,uint256 _gridNo) public 
                        CheckIfUserExist(SmartmeterAddr, AppNodeAddr) onlyOwner() CheckIfGridDoesntExist(_gridNo) {
        uint256 _id = users.push(User(_typeOfUser,_gridNo,0,0,grids[gridIDToNo[_gridNo]].StartTime,new uint[](0),new uint[][](0),new uint[][](0),
        new uint[](0),0,1,0)) -1 ;
        userIDtoAddress[_id]= SmartmeterAddr;
        userAddresstoID[SmartmeterAddr]=_id;
        grids[gridIDToNo[_gridNo]].usrs.push(SmartmeterAddr); 
        grids[gridIDToNo[_gridNo]].EngyMktConsensus.push(1);							
        userIDtoAddrInMG[SmartmeterAddr] = grids[gridIDToNo[_gridNo]].usrs.length-1;	
        _insertNewUser(_gridNo,SmartmeterAddr);
        _initializeBuyQty(SmartmeterAddr);
        AppToSmartmeter[AppNodeAddr]=SmartmeterAddr;
        if(users[userAddresstoID[SmartmeterAddr]].typeOfUser==2){
            _initializesSeller(SmartmeterAddr);
        }
        _initialSort(_gridNo);
    }


	function changeUserType(address SmartmeterAddr,address AppNodeAddr) public onlyOwner() CheckIfUserdoesntExist(SmartmeterAddr, AppNodeAddr){
    	users[userAddresstoID[SmartmeterAddr]].typeOfUser=2;
    	_initializesSeller(SmartmeterAddr);    
	} 


	
	function createGrid(uint256 _GridNo, uint256 _priceType) public onlyOwner() CheckIfGridExist(_GridNo) {
        uint256 _Gid = grids.push(Grid(0,0,block.timestamp,_priceType,new uint[](0),new address[](0),
        block.timestamp,new uint[][](0),new uint[][](0),new address[][](0),new uint[][](0),new uint[][](0)
        ,new address[][](0), 15,2, 
        new address[][](0), new address[][](0),new uint[][](0), new uint[][](0), new uint[](0))) -1 ;
        gridNoToID[_Gid]= _GridNo;
        gridIDToNo[_GridNo]=_Gid;
        grids[gridIDToNo[_GridNo]].usrs.push(Utility); 
        grids[gridIDToNo[_GridNo]].EngyMktConsensus.push(1);	
        _insertGridUtility(_GridNo);
    }


    
	function setMeterData(uint256 _consumedProducedEnergy, uint256 flag) public OnlySmartMeter(msg.sender) {
        if(block.timestamp >= (users[userAddresstoID[msg.sender]].time+userBalTime))  {
		     _balanceUser();
        } 
		_payUserDebt(msg.sender);
	    if(users[userAddresstoID[msg.sender]].RelayState==1)  {
            if(flag == 1) {
                users[userAddresstoID[msg.sender]].consumedEnergy +=  _consumedProducedEnergy;
                grids[gridIDToNo[users[userAddresstoID[msg.sender]].gridNo]].totalConsumption += 
                _consumedProducedEnergy;
            }
            if(flag == 2) {
                users[userAddresstoID[msg.sender]].producedEnergy +=  _consumedProducedEnergy;
                grids[gridIDToNo[users[userAddresstoID[msg.sender]].gridNo]].totalProduction += 
                _consumedProducedEnergy;
            }
	    }
    }


	
	function setExchangeRate(uint256 _rate) public onlyOwner() {
        Token_rate = _rate;
    }


    
    function _balanceUser() internal {
        /* Insert logic for _balanceUserConsumption */
        if (users[userAddresstoID[msg.sender]].typeOfUser==2){
		    /* Insert logic for _balanceUserProduction */    

        } else{
            users[userAddresstoID[msg.sender]].producedEnergy =0;
        }   
		grids[gridIDToNo[users[userAddresstoID[msg.sender]].gridNo]].EngyMktConsensus[userIDtoAddrInMG[msg.sender]]=1;
		/* Insert logic for _resetGridTime */(users[userAddresstoID[msg.sender]].gridNo); 
		if (block.timestamp >= userBalTime + grids[gridIDToNo[users[userAddresstoID[msg.sender]].gridNo]].StartTime){
		    /* Insert logic for _resetBalGrid */(users[userAddresstoID[msg.sender]].gridNo);
		}
    }


    
    function _resetGridTime(uint256 locgridN) internal {
    if (block.timestamp >= grids[gridIDToNo[locgridN]].ResetTime + userBalTime) {
        while (block.timestamp >= grids[gridIDToNo[locgridN]].ResetTime + userBalTime) {
            users[userAddresstoID[msg.sender]].time = gridbalancetime + grids[gridIDToNo[locgridN]].ResetTime;
            grids[gridIDToNo[locgridN]].ResetTime += gridbalancetime;
        }
    } else {
        users[userAddresstoID[msg.sender]].time = grids[gridIDToNo[locgridN]].ResetTime;
    }
}



    
    function restartTrade() public onlyAlarm(){
        uint256 i;InitialTime=block.timestamp;
        for( i=0; i<grids.length; i++) 	{
            grids[i].StartTime=block.timestamp;
		    grids[i].ResetTime=block.timestamp;
		}
        for( i=0; i<users.length; i++) {
		    users[i].time=block.timestamp;
		}
    }


    
    function changeGridBalTime(uint256 _TimeInMinutes) public onlyOwner() {
        userBalTime = (_TimeInMinutes-1)*60;
        gridbalancetime = _TimeInMinutes*60;
    }


    
    function _setRelayState(bool logic,uint256 _amtTopay) internal{
        if(logic==true) {
            users[userAddresstoID[msg.sender]].RelayState=1;       
        }
        else{
		    users[userAddresstoID[msg.sender]].RelayState=0;
		    users[userAddresstoID[msg.sender]].userDebt +=_amtTopay;  
		}
		uint256 itT = _getIterationIndex();
	    users[userAddresstoID[msg.sender]].BQty[itT]=0;
        users[userAddresstoID[msg.sender]].consumedEnergy=0;
    }


    
    function viewRelayState(address SMadress) public view returns(uint) {
        return users[userAddresstoID[SMadress]].RelayState;
    }


    
    function _payUserDebt(address _user) internal  {
	    if (users[userAddresstoID[msg.sender]].userDebt>0){   
            uint256 debtprice1=((users[userAddresstoID[_user]].userDebt)/3600)+1;
            debtprice1=debtprice1*Token_rate*grids[gridIDToNo[users[userAddresstoID[_user]].gridNo]].utilitySellPrice;
            if (debtprice1>0 && balanceOf[msg.sender] > debtprice1){
               transfer(Utility, debtprice1);
	           users[userAddresstoID[_user]].userDebt=0;      
	           users[userAddresstoID[_user]].RelayState=1;
	        }
	        if(debtprice1>0 && balanceOf[msg.sender] < debtprice1) {
	           users[userAddresstoID[_user]].RelayState=0;
		    } 
	    }
    }


    
    function setUtilitySellBuyPrice(uint256 Sellprice, uint256 BuyPrice, uint256 _gridNu) public OnlyUtility (msg.sender) {   
        grids[gridIDToNo[_gridNu]].utilitySellPrice=Sellprice;
        grids[gridIDToNo[_gridNu]].utilityBuyPrice=BuyPrice;
    }


	
	function _payUtilityDebt(uint256 _gridNu) internal {
	    uint256 i;
	    if(msg.sender == ExchangeAddr) {
			for( i = 0; i < grids[gridIDToNo[_gridNu]].usrs.length; i++) {  
				if (transferFrom(Utility, grids[gridIDToNo[users[userAddresstoID[msg.sender]].gridNo]].usrs[i], users[userAddresstoID[grids[gridIDToNo[users[userAddresstoID[msg.sender]].gridNo]].usrs[i]]].UtilityDebt) == true){ 
					users[userAddresstoID[grids[gridIDToNo[users[userAddresstoID[msg.sender]].gridNo]].usrs[i]]].UtilityDebt = 0;
				}
            }
	    }
	}


	
	function viewQtyBought(address AppAddr) public view returns(uint[] memory){
	    uint256 cIndex=_getIterationIndex();
	    uint256 cnt=cIndex;
	    uint256 cnt2=0;
	    uint256 index=ithTime;
	    uint[] memory EnergyBQty = new uint[] (index);        
        for(uint256 i=0; i<index; i++){
            if (cIndex<index){
            EnergyBQty[i]=users[userAddresstoID[AppToSmartmeter[AppAddr]]].BQty[cIndex]; 
            cIndex++;

            }
            else{
                if (cnt2<cnt){
                    EnergyBQty[i]=users[userAddresstoID[AppToSmartmeter[AppAddr]]].BQty[cnt2]; 
                    cnt2++;
                }
            }



        }
        return EnergyBQty ;
	}


	
	function viewQtySoldAndPrice(address AppAddr, uint256 _tim) public view returns (uint[] memory Energy, uint[] memory Prices){
	    uint256 l=0;
	    if (users[userAddresstoID[AppToSmartmeter[AppAddr]]].sellcount[_tim]>users[userAddresstoID[AppToSmartmeter[AppAddr]]].SQty[_tim].length){
	        l=users[userAddresstoID[AppToSmartmeter[AppAddr]]].SQty[_tim].length;

	    }
	    else{
	        l=users[userAddresstoID[AppToSmartmeter[AppAddr]]].sellcount[_tim];
	    }
	    users[userAddresstoID[AppToSmartmeter[AppAddr]]].sellcount[_tim];
	    uint[] memory EnergySoldQty = new uint[] (l); 
	    uint[] memory EnergySoldPrice = new uint[] (l); 
	    for(uint256 i=0; i<l; i++){
	        EnergySoldQty[i]=users[userAddresstoID[AppToSmartmeter[AppAddr]]].SQty[_tim][i];
	        EnergySoldPrice[i]=users[userAddresstoID[AppToSmartmeter[AppAddr]]].SPrice[_tim][i];
	    }
	    return (EnergySoldQty,EnergySoldPrice);
	}


	
	function _resetBalGrid(uint256 _gridNUmm) internal {
		    grids[gridIDToNo[_gridNUmm]].StartTime =grids[gridIDToNo[_gridNUmm]].ResetTime;   
		    grids[gridIDToNo[_gridNUmm]].totalProduction =0;
		    grids[gridIDToNo[_gridNUmm]].totalConsumption=0;
	}


	
	function placeSellOffer(uint256 _price, uint256 _Qty, uint256 _tim ) public OnlyAppNode(msg.sender) AskEnergyRequirements(_price) 
	{
	    uint256 _GridNo=users[userAddresstoID[AppToSmartmeter[msg.sender]]].gridNo;
	    uint256 indxS=_getArrayIndex(grids[gridIDToNo[_GridNo]].ESaddr[_tim], AppToSmartmeter[msg.sender]);
	    uint256 indxB=	_getArrayIndex(grids[gridIDToNo[_GridNo]].EBaddr[_tim], AppToSmartmeter[msg.sender]);
	    grids[gridIDToNo[users[userAddresstoID[AppToSmartmeter[msg.sender]]].gridNo]].ESq[_tim][indxS]=_Qty;
	    grids[gridIDToNo[users[userAddresstoID[AppToSmartmeter[msg.sender]]].gridNo]].EBq[_tim][indxB]=0;
	    grids[gridIDToNo[users[userAddresstoID[AppToSmartmeter[msg.sender]]].gridNo]].ESp[_tim][indxS]=_price;
        _sortSellOffers(users[userAddresstoID[AppToSmartmeter[msg.sender]]].gridNo, _tim);
        _sortBuyOffers(users[userAddresstoID[AppToSmartmeter[msg.sender]]].gridNo, _tim);
	}


	
	function placeBuyOffer(uint256 _price, uint256 _Qty, uint256 _tim ) public  OnlyAppNode(msg.sender)BidEnergyRequirements (_Qty,_price) 	{ 
	    uint256 _GridNo=users[userAddresstoID[AppToSmartmeter[msg.sender]]].gridNo;
	    uint256 indxS=_getArrayIndex(grids[gridIDToNo[_GridNo]].ESaddr[_tim], AppToSmartmeter[msg.sender]);
	    uint256 indxB=	_getArrayIndex(grids[gridIDToNo[_GridNo]].EBaddr[_tim], AppToSmartmeter[msg.sender]);
	    grids[gridIDToNo[users[userAddresstoID[AppToSmartmeter[msg.sender]]].gridNo]].EBq[_tim][indxB]=_Qty;
	    grids[gridIDToNo[users[userAddresstoID[AppToSmartmeter[msg.sender]]].gridNo]].ESq[_tim][indxS]=0;
	    grids[gridIDToNo[users[userAddresstoID[AppToSmartmeter[msg.sender]]].gridNo]].EBp[_tim][indxB]=_price;
	    _sortSellOffers(users[userAddresstoID[AppToSmartmeter[msg.sender]]].gridNo, _tim);
	    _sortBuyOffers(users[userAddresstoID[AppToSmartmeter[msg.sender]]].gridNo, _tim);
	}


	
	function _sortSellOffers(uint256 _GridNo,uint256 _tim) internal  {
		(grids[gridIDToNo[_GridNo]].ESp[_tim],grids[gridIDToNo[_GridNo]].ESq[_tim],
		grids[gridIDToNo[_GridNo]].ESaddr[_tim]) = 
		_sortSellPrices(grids[gridIDToNo[_GridNo]].ESp[_tim],grids[gridIDToNo[_GridNo]].ESq[_tim],
		grids[gridIDToNo[_GridNo]].ESaddr[_tim]);
    }


    
    function _sortBuyOffers(uint256 _GridNo, uint256 _tim) internal  {
        (grids[gridIDToNo[_GridNo]].EBp[_tim],grids[gridIDToNo[_GridNo]].EBq[_tim], 
        grids[gridIDToNo[_GridNo]].EBaddr[_tim]) = 
        _sortBuyPrices(grids[gridIDToNo[_GridNo]].EBp[_tim],grids[gridIDToNo[_GridNo]].EBq[_tim], 
        grids[gridIDToNo[_GridNo]].EBaddr[_tim]);
    }


    
    function viewSellOffers(uint256 _GridNo,uint256 _tim) public view  returns (uint[] memory Sell_Price, uint[] memory Sell_Qty) {
        return (grids[gridIDToNo[_GridNo]].ESp[_tim], grids[gridIDToNo[_GridNo]].ESq[_tim]); 
    }


    
    function viewBuyOffers(uint256 _GridNo, uint256 _tim) public view   returns (uint[] memory Buy_Price, uint[] memory Buy_Qty) {

        return (grids[gridIDToNo[_GridNo]].EBp[_tim], grids[gridIDToNo[_GridNo]].EBq[_tim]); 
    }


    function viewMatchedEnergy(uint256 _GridNo, uint256 _tim) public view   returns (address[] memory Buyer_Addr, 
        address[] memory Seller_Addr, 
        uint[] memory Matched_Qty, 
        uint[] memory Price) {
        uint256 l = grids[gridIDToNo[_GridNo]].matchedLength[_tim];
        address[] memory Buyer = new address[] (l);
        address[] memory Seller = new address[] (l);
        uint[] memory Av_Qty = new uint[] (l);   
        uint[] memory Av_Price = new uint[] (l);        
        for(uint256 i=0; i<l; i++){
            Buyer[i] = grids[gridIDToNo[_GridNo]].matchedBuyer[_tim][i];
            Seller[i] = grids[gridIDToNo[_GridNo]].matchedSeller[_tim][i];
            Av_Qty[i] = grids[gridIDToNo[_GridNo]].soldQuantity[_tim][i];
            Av_Price[i]=grids[gridIDToNo[_GridNo]].soldPrice[_tim][i];
        }
        return (Buyer, Seller, Av_Qty, Av_Price); 
    }


    
	function clearEnergyOrder(address memberAddr) public onlyAlarm() { 
	    uint256 Gridnun=users[userAddresstoID[memberAddr]].gridNo;
		if (viewMarketConsensus(Gridnun)==true){
			for (uint256 ith=0; ith<ithTime;ith++){  
				_matchBuyAndSellOffers(Gridnun, ith);
			}
        _resetMarketConsensus(Gridnun);
        _payUtilityDebt(Gridnun);
       }
    }


    uint256 r; uint256 j;       uint256 _mcp;




    
    function _remMatchedOffers(uint256 _GridNo, uint256 _ith) internal  {
        for (uint256 i = 0; i < grids[gridIDToNo[_GridNo]].soldQuantity[_ith].length; i++){   
            grids[gridIDToNo[_GridNo]].soldQuantity[_ith][i] = 0;    
        }
        grids[gridIDToNo[_GridNo]].matchedLength[_ith] = 0; 
    } 

function _assignMatchedPrice(uint gridNo, uint price) internal {
    Grid storage grid = grids[gridNo];
    uint matchedLength = grid.matchedLength.length;

    for (uint i = 0; i < matchedLength; i++) {
        for (uint jm = 0; jm < grid.matchedBuyer[i].length; jm++) {
            grid.soldPrice[i][jm] = price;
        }
        for (uint k = 0; k < grid.matchedSeller[i].length; k++) {
            grid.soldPrice[i][k] = price;
        }
    }
}
    
    function _matchBuyAndSellOffers(uint256 _GridNo, uint256 _ith) internal  {
        uint256 df;
        uint256 y=1; 
       r =0; j=0; 
        uint256 Avp1; uint256 Avq1;uint256 Amt;
        uint256 itT=_getCurrentIteration();
	    if (_ith==itT){
	        _remMatchedOffers( _GridNo, _ith);   
	    }
        if (grids[gridIDToNo[_GridNo]].priceType==2){
       _mcp= _determineMCP(grids[gridIDToNo[_GridNo]].ESp[_ith], grids[gridIDToNo[_GridNo]].ESq[_ith], 
        grids[gridIDToNo[_GridNo]].EBp[_ith],grids[gridIDToNo[_GridNo]].EBq[_ith],grids[gridIDToNo[_GridNo]].EBaddr[_ith]);
        }
        while(y>0 && j<grids[gridIDToNo[_GridNo]].EBp[_ith].length && r< grids[gridIDToNo[_GridNo]].ESp[_ith].length){
	        if(grids[gridIDToNo[_GridNo]].ESp[_ith][r]<= grids[gridIDToNo[_GridNo]].EBp[_ith][j]) {
		        if (grids[gridIDToNo[_GridNo]].ESq[_ith][r] == grids[gridIDToNo[_GridNo]].EBq[_ith][j]){
                    Avp1 = (grids[gridIDToNo[_GridNo]].ESp[_ith][r] + grids[gridIDToNo[_GridNo]].EBp[_ith][j])/2;
                    Avq1 = grids[gridIDToNo[_GridNo]].ESq[_ith][r];
                    if (Avq1==0){
                     j++; r++;
                    } 
                    else {
                        Amt =Avp1*Avq1*Token_rate;
                        if (balanceOf[grids[gridIDToNo[_GridNo]].EBaddr[_ith][j]]>Amt ){
                              if (grids[gridIDToNo[_GridNo]].priceType==2){
                                    _assignMatchedPrice( _mcp, Avq1, _GridNo, _ith,r,j); 
                              }
                              else{
                                     _assignMatchedPrice( Avp1, Avq1, _GridNo, _ith,r,j);
                              }


                            grids[gridIDToNo[_GridNo]].ESq[_ith][r]=0;
                            r++; 
                        }
                    grids[gridIDToNo[_GridNo]].EBq[_ith][j]=0;
                    j++;
		            }
		        }
		        else if (grids[gridIDToNo[_GridNo]].ESq[_ith][r] > grids[gridIDToNo[_GridNo]].EBq[_ith][j]){
		        df= grids[gridIDToNo[_GridNo]].ESq[_ith][r] - grids[gridIDToNo[_GridNo]].EBq[_ith][j];
	            Avp1 = (grids[gridIDToNo[_GridNo]].ESp[_ith][r] + grids[gridIDToNo[_GridNo]].EBp[_ith][j])/2;
		             Avq1 = grids[gridIDToNo[_GridNo]].EBq[_ith][j];
		             if (Avq1==0){
		                j++; 
		             } 
		             else {
                        Amt =Avp1*Avq1*Token_rate;
                        if (balanceOf[grids[gridIDToNo[_GridNo]].EBaddr[_ith][j]]>Amt ){
                              if (grids[gridIDToNo[_GridNo]].priceType==2){
                                    _assignMatchedPrice( _mcp, Avq1, _GridNo, _ith,r,j); 
                              }
                              else{
                                     _assignMatchedPrice( Avp1, Avq1, _GridNo, _ith,r,j);
                              }
                            grids[gridIDToNo[_GridNo]].ESq[_ith][r]= df; 

                            }
                    grids[gridIDToNo[_GridNo]].EBq[_ith][j]=0; 
                    j++;
                    }
		        }
	            else {
		             df=grids[gridIDToNo[_GridNo]].EBq[_ith][j] - grids[gridIDToNo[_GridNo]].ESq[_ith][r] ;
	        	     Avp1 = (grids[gridIDToNo[_GridNo]].ESp[_ith][r] + grids[gridIDToNo[_GridNo]].EBp[_ith][j])/2;
		             Avq1=  grids[gridIDToNo[_GridNo]].ESq[_ith][r];
		             if (Avq1==0){
		                 r++;
		             } 
		             else {
		                Amt =Avp1*Avq1*Token_rate;
		                if (balanceOf[grids[gridIDToNo[_GridNo]].EBaddr[_ith][j]]>Amt ){
                              if (grids[gridIDToNo[_GridNo]].priceType==2){
                                    _assignMatchedPrice( _mcp, Avq1, _GridNo, _ith,r,j); 
                              }
                              else{
                                     _assignMatchedPrice( Avp1, Avq1, _GridNo, _ith,r,j);
                              }
                            grids[gridIDToNo[_GridNo]].EBq[_ith][j]= df; 
                            grids[gridIDToNo[_GridNo]].ESq[_ith][r]=0;
                            r++;
                        }
                    }
	            }
        	}
        	else{
        	    y=0;

	            itT=_getCurrentIteration();
	            if (_ith==itT){
	                _remUnmatchedOffers( _GridNo, _ith);
                }
        	    _sortSellOffers(_GridNo,_ith);
	            _sortBuyOffers(_GridNo, _ith);

    	    }
        }
    }

   
    function _determineMCP(uint[] memory sellPrice, 
    uint[] memory sellQty, 
    uint[] memory buyPrice, 
    uint[] memory buyQty, 
    address[] memory buyAddr) internal returns(uint256 _Mcp){
        uint256 df;
        uint256 y=1; 
       r =0; j=0; 
        uint256 Avp1; uint256 Avq1;uint256 Amt;
        while(y>0 && j<buyPrice.length && r< sellPrice.length){
	        if(sellPrice[r]<= buyPrice[j]) {
		        if (sellQty[r] == buyQty[j]){
                    Avp1 = (sellPrice[r] + buyPrice[j])/2;
                    Avq1 = sellQty[r];
                    if (Avq1==0){
                     j++; r++;
                    } 
                    else {
                        Amt =Avp1*Avq1*Token_rate;
                        if (balanceOf[buyAddr[j]]>Amt ){
                            sellQty[r]=0;
                            r++; 
                        }
                    buyQty[j]=0;
                    j++;
		            }
		        }
		        else if (sellQty[r] > buyQty[j]){
		        df= sellQty[r] - buyPrice[j];
	            Avp1 = (sellPrice[r] + buyPrice[j])/2;
		             Avq1 = buyQty[j];
		             if (Avq1==0){
		                j++; 
		             } 
		             else {
                        Amt =Avp1*Avq1*Token_rate;
                        if (balanceOf[buyAddr[j]]>Amt ){
                            sellQty[r]= df; 

                            }
                    buyQty[j]=0; 
                    j++;
                    }
		        }
	            else {
		             df=buyQty[j] - sellQty[r] ;
	        	     Avp1 = (sellPrice[r] + buyPrice[j])/2;
		             Avq1=  sellQty[r];
		             if (Avq1==0){
		                 r++;
		             } 
		             else {
		                Amt =Avp1*Avq1*Token_rate;
		                if (balanceOf[buyAddr[j]]>Amt ){
                            buyQty[j]= df; 
                            sellQty[r]=0;
                            r++;
                        }
                    }
	            }
        	}
        	else{
        	    y=0;

    	    }
        }
        _mcp=Avp1;

       return _mcp;
    }




    
    function _remUnmatchedOffers(uint256 _GridNo, uint256 _ith) internal  {
	    for (uint256 i=0; i<grids[gridIDToNo[_GridNo]].ESq[_ith].length;i++){   
	        grids[gridIDToNo[_GridNo]].ESq[_ith][i] = 0;    
	    }
	    for (uint i=0; i<grids[gridIDToNo[_GridNo]].EBq[_ith].length;i++){   
	        grids[gridIDToNo[_GridNo]].EBq[_ith][i] = 0;    
	    }
    }


	
	function _insertNewUser(uint256 gridNo,address _sMaddr) internal {
	    for (uint256 ith=0; ith<ithTime;ith++){  
			grids[gridIDToNo[gridNo]].ESp[ith].push(grids[gridIDToNo[gridNo]].utilitySellPrice-1);
			grids[gridIDToNo[gridNo]].ESq[ith].push(0);
			grids[gridIDToNo[gridNo]].EBp[ith].push(grids[gridIDToNo[gridNo]].utilityBuyPrice+1);
			grids[gridIDToNo[gridNo]].EBq[ith].push(0);
			grids[gridIDToNo[gridNo]].EBaddr[ith].push(_sMaddr);
			grids[gridIDToNo[gridNo]].ESaddr[ith].push(_sMaddr);
	    }
    }


	
	function _insertGridUtility(uint256 gridNo) internal {
	    for (uint256 ith=0; ith<ithTime;ith++){  
			grids[gridIDToNo[gridNo]].matchedBuyer.push([0]);
			grids[gridIDToNo[gridNo]].matchedSeller.push([0]);
			grids[gridIDToNo[gridNo]].soldQuantity.push([0]);
			grids[gridIDToNo[gridNo]].soldPrice.push([0]);
			grids[gridIDToNo[gridNo]].matchedLength.push(0);
			grids[gridIDToNo[gridNo]].ESp.push([grids[gridIDToNo[gridNo]].utilitySellPrice]);
			grids[gridIDToNo[gridNo]].ESq.push([99999999999999]);
			grids[gridIDToNo[gridNo]].EBp.push([grids[gridIDToNo[gridNo]].utilityBuyPrice]);
			grids[gridIDToNo[gridNo]].EBq.push([99999999999999]);
			grids[gridIDToNo[gridNo]].EBaddr.push([Utility]);
			grids[gridIDToNo[gridNo]].ESaddr.push([Utility]);
        }
    }


    
    function viewGridSellBuyPrice(uint256 _GridNo) public  view returns(uint256 GenSellPrice, uint256 GenBuyPrice){
        return(grids[gridIDToNo[_GridNo]].utilitySellPrice, grids[gridIDToNo[_GridNo]].utilityBuyPrice);
    }


    
    function _initializesSeller(address UserAddr) internal {
        uint256 i;
        for (uint256 ith = 0; ith < ithTime; ith++){ 
            users[userAddresstoID[UserAddr]].SQty.push([0]);
            users[userAddresstoID[UserAddr]].SPrice.push([0]);
        }
        for (i = 1; i < grids[gridIDToNo[users[userAddresstoID[UserAddr]].gridNo]].usrs.length; i++){
            for (uint ith=0; ith<ithTime;ith++){ 
                users[userAddresstoID[grids[gridIDToNo[users[userAddresstoID[UserAddr]].gridNo]].usrs[i]]].SQty[ith].push(0);
                users[userAddresstoID[grids[gridIDToNo[users[userAddresstoID[UserAddr]].gridNo]].usrs[i]]].SPrice[ith].push(0); 
                }
        }
        for( i=0; i<grids[gridIDToNo[users[userAddresstoID[UserAddr]].gridNo]].usrs.length-1; i++){
              for (uint ith=0; ith<ithTime;ith++){  
            users[userAddresstoID[UserAddr]].SQty[ith].push(0);
            users[userAddresstoID[UserAddr]].SPrice[ith].push(0);   
            users[userAddresstoID[UserAddr]].sellcount.push(0);             
            }
        }
    }


        
    function _initializeBuyQty(address UserAddr) internal {
        for (uint256 ith=0; ith<ithTime;ith++){ 
            users[userAddresstoID[UserAddr]].BQty.push(0);
        } 
    }


    
    function checkSMNode(address _addrs) public view onlyAlarm() returns(bool){
        if(_addrs==userIDtoAddress[userAddresstoID[_addrs]]){
            return true;
        }
        else{return false;}
    }


    
	function setUtilityAddr (address _UtiAddr) public onlyOwner() returns(bool) {
        Utility=   _UtiAddr;
	    return true;
	}


	function setExchangeAddr(address _ExchAddr) public onlyOwner() returns(bool) {
	    ExchangeAddr = _ExchAddr;
	    return true;
	}	 



    
    function viewMarketConsensus(uint256 _gridNum) public view onlyAlarm() returns(bool){
        uint256 McountConsencus=0;
        for (uint256 i=0; i<grids[gridIDToNo[_gridNum]].EngyMktConsensus.length;i++){
            McountConsencus += grids[gridIDToNo[_gridNum]].EngyMktConsensus[i];
        }
        uint256 percentAgreeM = (McountConsencus*100)/(grids[gridIDToNo[_gridNum]].EngyMktConsensus.length);
        if(percentAgreeM>=51){
            return true;
        }
        else{return false;}
    }


     
    function _resetMarketConsensus(uint256 _gridNum) internal  {
        for (uint256 i=1; i<grids[gridIDToNo[_gridNum]].EngyMktConsensus.length;i++){
           grids[gridIDToNo[_gridNum]].EngyMktConsensus[i] = 0;
        }
    }


        
    function viewgridProducedConsumedEnergy(uint256 _gridNum) public view returns(uint, uint)  {
        return (grids[gridIDToNo[_gridNum]].totalProduction,
               grids[gridIDToNo[_gridNum]].totalConsumption);
    }


	    
    function viewUserProducedConsumedEnergy(address _userSMaddr) public view returns(uint, uint)  {    
        return (users[userAddresstoID[_userSMaddr]].producedEnergy,
               users[userAddresstoID[_userSMaddr]].consumedEnergy);
    }


	

	
    


    function _getIterationIndex() internal view returns(uint256 previous){
        uint256 itTim;
		uint256 it_Time=block.timestamp-InitialTime;   
		uint256 itV=it_Time/1440; 
		uint256 divValue =it_Time-1440*itV;
		it_Time=(divValue/60);
		if (it_Time==0){
		    itTim=ithTime-1;
		}
		else{
		   itTim= it_Time-1;
		}
		return itTim;  
	}

    function _getCurrentIteration() internal view returns(uint256 current){
        uint256 ITT=_getIterationIndex();
        uint256 iTim;
        if (ITT==ithTime-1){
		    iTim=0;
		 }
		else{
		    iTim= ITT+1;
		 }
		 return iTim; 
    }

    
    function currentTimeStep() public view returns (uint256 step){
        uint256 timeStep=_getCurrentIteration();
        return timeStep;
    }


        
    function _initialSort(uint256 gridNu) internal {
		for (uint256 ith = 0; ith < ithTime; ith++){       
			_sortSellOffers(gridNu, ith);
			_sortBuyOffers(gridNu, ith);
		}
    }


    
    function _getArrayIndex(address[] AddrArray, address uniqAddr) internal pure returns(uint256 indx){
        indx=0;
         for (uint256 i=0; i<AddrArray.length;i++){
            if(AddrArray[i]==uniqAddr){
                indx=i;  
            }
        } 
        return indx;
    }
}

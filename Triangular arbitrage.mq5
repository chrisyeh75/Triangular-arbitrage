//+------------------------------------------------------------------+
//|                                                     PairsDis.mq5 |
//|                        Copyright 2017, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2017, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
#include<Trade\Trade.mqh>
#include<Trade\AccountInfo.mqh>

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+

//entry when gap is at this point
input double entry = 0.3;
//exit when gap is at this point
input double exit = 0.1;
//minimum gap
input double profitThreshold = 0;
//base lot size
input double BLS = 0.22;

//to keep track of which trades we are operating
bool LLS = false, SSL = false, LLSC = false, SSLC = false;
//to keep current prices
double eurusdAsk, eurusdBid, usdjpyAsk, usdjpyBid, eurjpyAsk, eurjpyBid, usdcadAsk, usdcadBid, cadjpyAsk, cadjpyBid;
//to keep current spreads
double eurusdSpread, usdcadSpread, usdjpySpread, eurjpySpread, cadjpySpread, sumSpreadEur, sumSpreadCad, prevBalance, profit;
double prevSumSpreadCad, prevSumSpreadEur, entryThreshCad, entryThreshEur, exitThreshCad, exitThreshEur, minSumspread;
//to calculate profit
CAccountInfo account;

int OnInit()
  {
//---

//---
   prevBalance = account.Balance();
   //calculate minimum entry requirement
   minSumspread = profitThreshold / ( entry - exit );


   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//---

  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+

//function for opening trades, sl and tp is 1000 points above and below
void trade(string symbol, ENUM_ORDER_TYPE orderType, double lots){

  CTrade  trade;
   int    digits=(int)SymbolInfoInteger(symbol,SYMBOL_DIGITS);
   double point=SymbolInfoDouble(symbol,SYMBOL_POINT);
   double price;
   if(orderType == ORDER_TYPE_BUY)
      price = SymbolInfoDouble(symbol,SYMBOL_ASK);
   else if(orderType == ORDER_TYPE_SELL)
      price = SymbolInfoDouble(symbol, SYMBOL_BID);
//--- calculate and normalize SL and TP levels
   double SL, TP;
   if(orderType == ORDER_TYPE_BUY){
      SL = NormalizeDouble(price-1000*point,digits);
      TP = NormalizeDouble(price+1000*point,digits);
   }
   if(orderType == ORDER_TYPE_SELL){
      SL = NormalizeDouble(price+1000*point,digits);
      TP = NormalizeDouble(price-1000*point,digits);
   }
//--- filling comments
   string comment;
   if(orderType == ORDER_TYPE_BUY)
    comment = "Buy " + symbol + " " + DoubleToString(lots, 2) + " at "+DoubleToString(price,digits);
    else
    comment = "Sell " + symbol + " " + DoubleToString(lots, 2) + " at "+DoubleToString(price,digits);
//--- everything is ready, trying to open a buy position
   if(!trade.PositionOpen(symbol,orderType,lots,price, NULL, NULL, comment))
     {
      //--- failure message
      
      Print("PositionOpen() method failed. Return code=",trade.ResultRetcode(),
            ". Code description: ",trade.ResultRetcodeDescription());
     }
   else
     {
     
      Print("PositionOpen() method executed successfully. Return code=",trade.ResultRetcode(),
            " (",trade.ResultRetcodeDescription(),")");
     }
     
 }

//function for closing orders
 void closeOrder(string symbol){
   CTrade trade;
    if(!trade.PositionClose(symbol))
     {
      //--- failure message
      Print("PositionClose() method failed. Return code=",trade.ResultRetcode(),
            ". Code description: ",trade.ResultRetcodeDescription());
     }
   else
     {
      Print("PositionClose() method executed successfully. Return code=",trade.ResultRetcode(),
            " (",trade.ResultRetcodeDescription(),")");
     }
}


//remember the price for printing to console
double memeurusd, memusdjpy, memeurjpy, memcadjpy, memusdcad, memdis;

void OnTick()
  {
//---
   //if balance less than 900 don't do anything (for testing on balance > 1000)
   if(account.Balance() < 900) return;
   
   //get current prices
   eurusdAsk = SymbolInfoDouble("EURUSD", SYMBOL_ASK);
   eurusdBid = SymbolInfoDouble("EURUSD", SYMBOL_BID);
   usdjpyAsk = SymbolInfoDouble("USDJPY", SYMBOL_ASK);
   usdjpyBid = SymbolInfoDouble("USDJPY", SYMBOL_BID);
   eurjpyAsk = SymbolInfoDouble("EURJPY", SYMBOL_ASK);
   eurjpyBid = SymbolInfoDouble("EURJPY", SYMBOL_BID);
   
   
   usdcadAsk = SymbolInfoDouble("USDCAD", SYMBOL_ASK);
   usdcadBid = SymbolInfoDouble("USDCAD", SYMBOL_BID);
   cadjpyAsk = SymbolInfoDouble("CADJPY", SYMBOL_ASK);
   cadjpyBid = SymbolInfoDouble("CADJPY", SYMBOL_BID);
   
   

   //if there is gap in data (price of 0), don't do anything
   if (eurusdAsk == 0 || eurusdBid == 0 || usdjpyAsk == 0 || usdjpyBid == 0 || eurjpyAsk == 0 ||
      eurjpyBid == 0 || usdcadAsk == 0 || usdcadBid == 0 || cadjpyAsk == 0 || cadjpyBid == 0)
      return;
   
   
   //converts spread to jpy
   eurusdSpread = (eurusdAsk - eurusdBid) * usdjpyAsk;
   usdcadSpread = (usdcadAsk - usdcadBid) * cadjpyAsk;
      
   usdjpySpread = usdjpyAsk - usdjpyBid;
   eurjpySpread = eurjpyAsk - eurjpyBid;
   cadjpySpread = cadjpyAsk - cadjpyBid;
   
   
   sumSpreadEur = eurusdSpread + usdjpySpread + eurjpySpread;
   sumSpreadCad = usdcadSpread + cadjpySpread + usdjpySpread; 
   

   
   //if there is no current order
   if(PositionsTotal() == 0) {
      
      //if current spread warrents an entry point less than minimum required
      if(sumSpreadCad < minSumspread)
         sumSpreadCad = minSumspread;
         
      if(sumSpreadEur < minSumspread)
         sumSpreadEur = minSumspread;
      
      if (usdcadAsk * cadjpyAsk < usdjpyBid - sumSpreadCad * entry){
         trade("USDCAD", ORDER_TYPE_BUY, BLS);
         trade("CADJPY", ORDER_TYPE_BUY, NormalizeDouble(BLS * usdcadBid, 1));
         trade("USDJPY", ORDER_TYPE_SELL, BLS);
         prevSumSpreadCad = sumSpreadCad;
         PrintFormat("ORDER OPENED, LLSC: %.7f  %.7f  %.7f", usdcadAsk * cadjpyAsk, usdjpyBid, usdjpyBid - usdcadAsk * cadjpyAsk);
         PrintFormat("usdcad: %.7f  cadjpy: %.7f   usdjpy: %.7f", usdcadAsk, cadjpyAsk, usdjpyBid);
         memusdcad = usdcadAsk;
         memcadjpy = cadjpyAsk;
         memusdjpy = usdjpyBid;
         memdis = usdjpyBid - usdcadAsk * cadjpyAsk;
         
         LLSC = true;
      }
      
      else if (usdcadBid * cadjpyBid > usdjpyAsk + sumSpreadCad * entry){
      //short short long
      trade("USDCAD", ORDER_TYPE_SELL, BLS);
      trade("CADJPY", ORDER_TYPE_SELL, NormalizeDouble(BLS * usdcadBid, 1));
      trade("USDJPY", ORDER_TYPE_BUY, BLS);
      prevSumSpreadCad = sumSpreadCad;
      PrintFormat("ORDER OPENED, SSLC: %.7f  %.7f  %.7f", usdcadBid * cadjpyBid, usdjpyAsk, usdcadBid * cadjpyBid - usdjpyAsk);
      PrintFormat("usdcad: %.7f  cadjpy: %.7f   usdjpy: %.7f", usdcadBid, cadjpyBid, usdjpyAsk);
      memusdcad = usdcadAsk;
         memcadjpy = cadjpyAsk;
         memusdjpy = usdjpyBid;
         memdis = usdcadBid * cadjpyBid - usdjpyAsk;
         
      SSLC = true;  
      }
      else if (eurusdAsk * usdjpyAsk < eurjpyBid - sumSpreadEur * entry){
      //long long short
      trade("EURUSD", ORDER_TYPE_BUY, BLS);
      trade("USDJPY", ORDER_TYPE_BUY, NormalizeDouble(BLS * eurusdBid, 1));
      trade("EURJPY", ORDER_TYPE_SELL, BLS);
      prevSumSpreadEur = sumSpreadEur;
      PrintFormat("ORDER OPENED, LLS: %.7f  %.7f  %.7f", eurusdAsk * usdjpyAsk, eurjpyBid, eurjpyBid - eurusdAsk * usdjpyAsk);
      PrintFormat("eurusd: %.7f     usdjpy: %.7f      eurjpy: %.7f", eurusdAsk, usdjpyAsk, eurjpyBid);
      memeurusd = eurusdAsk;
      memusdjpy = usdjpyAsk;
      memeurjpy = eurjpyBid;
      memdis = eurjpyBid - eurusdAsk * usdjpyAsk;
      
      LLS = true;
      }
      else if (eurusdBid * usdjpyBid > eurjpyAsk + sumSpreadEur * entry){
      //short short long
      trade("EURUSD", ORDER_TYPE_SELL, BLS);
      trade("USDJPY", ORDER_TYPE_SELL, NormalizeDouble(BLS * eurusdBid, 1));
      trade("EURJPY", ORDER_TYPE_BUY, BLS);
      prevSumSpreadEur = sumSpreadEur;
      PrintFormat("ORDER OPENED, SSL: %.7f  %.7f  %.7f", eurusdBid * usdjpyBid, eurjpyAsk, eurusdBid * usdjpyBid - eurjpyAsk);
      PrintFormat("eurusd: %.7f     usdjpy: %.7f      eurjpy: %.7f", eurusdAsk, usdjpyAsk, eurjpyBid);
      memeurusd = eurusdAsk;
      memusdjpy = usdjpyAsk;
      memeurjpy = eurjpyBid;
      memdis = eurusdBid * usdjpyBid - eurjpyAsk;
      SSL = true;  
      }
   }
   
   
   //if we are in trade, check closing conditions
   else if (PositionsTotal() != 0){
      
   
   
      if (usdcadBid * cadjpyBid > usdjpyAsk - prevSumSpreadCad * exit && LLSC){
         closeOrder("USDCAD");
         closeOrder("CADJPY");
         closeOrder("USDJPY");
         
         
         profit = account.Balance() - prevBalance;
         
         
         
         
         double a = (usdcadBid - memusdcad) / usdcadBid * 100000 * 0.22;
         double b = (cadjpyBid - memcadjpy) / usdjpyBid * 100000 * NormalizeDouble(0.22 * usdcadBid, 2);
         double c = (memusdjpy - usdjpyAsk) / usdjpyBid * 100000 * 0.22; 
         
         PrintFormat("ORDER CLOSED: %.7f  %.7f  %.7f", usdcadBid * cadjpyBid, usdjpyAsk, usdjpyAsk - usdcadBid * cadjpyBid);
         PrintFormat("usdcad: %.7f  cadjpy: %.7f   usdjpy: %.7f", usdcadBid, cadjpyBid, usdjpyAsk);
         PrintFormat("Expected profit: %.7f + %.7f + %.7f = %.7f", a, b, c, a+b+c);
         
         
         PrintFormat("Difference: %.7f", a+b+c - profit);
         PrintFormat("Discrepency change: %.7f", memdis - (usdjpyAsk - usdcadBid * cadjpyBid));
         
         
         
         
         
         
         if( profit < 0 )
         PrintFormat("----------------------------------------------------------------- NEGATIVE PROFIT ---- %.7f", profit);
         
         else
         PrintFormat("Profit: %.7f", profit);
         
         prevBalance = account.Balance();
         LLSC = false;
      }
      
   
      
      else if (usdcadAsk * cadjpyAsk < usdjpyBid + prevSumSpreadCad * exit && SSLC){
         closeOrder("USDCAD");
         closeOrder("CADJPY");
         closeOrder("USDJPY");
         
         double a = (memusdcad - usdcadAsk) / usdcadBid * 100000 * 0.22;
         double b = (memcadjpy - cadjpyAsk) / usdjpyBid * 100000 * NormalizeDouble(0.22 * usdcadBid, 2);
         double c = (usdjpyBid - memusdjpy) / usdjpyBid * 100000 * 0.22; 
         
         PrintFormat("ORDER CLOSED: %.7f  %.7f  %.7f", usdcadBid * cadjpyBid, usdjpyAsk, usdcadBid * cadjpyBid - usdjpyBid);
         PrintFormat("usdcad: %.7f  cadjpy: %.7f   usdjpy: %.7f", usdcadBid, cadjpyBid, usdjpyAsk);
         PrintFormat("Expected profit: %.7f + %.7f + %.7f = %.7f", a, b, c, a+b+c);
         
         
         PrintFormat("Difference: %.7f", a+b+c - profit);
         PrintFormat("Discrepency change: %.7f", memdis - (usdjpyAsk - usdcadBid * cadjpyBid));
         
         
         
         profit = account.Balance() - prevBalance;
         
         if( profit < 0 )
         PrintFormat("----------------------------------------------------------------- NEGATIVE PROFIT ---- %.7f", profit);
         
         else
         PrintFormat("Profit: %.7f", profit);
         
         prevBalance = account.Balance();
         SSLC = false;
      } 
         
   
      
      else if (eurusdBid * usdjpyBid > eurjpyAsk - prevSumSpreadEur * exit && LLS){
         closeOrder("EURUSD");
         closeOrder("USDJPY");
         closeOrder("EURJPY");
         
         
         
         profit = account.Balance() - prevBalance;
         
         
         
         double a = (eurusdBid - memeurusd) * 100000 * 0.22;
         double b = (usdjpyBid - memusdjpy) / usdjpyBid * 100000 * 0.23;
         double c = (memeurjpy - eurjpyAsk) / usdjpyBid * 100000 * 0.22; 
         
         PrintFormat("ORDER CLOSED: %.7f  %.7f  %.7f", eurusdBid * usdjpyBid, eurjpyAsk, eurjpyAsk - eurusdBid * usdjpyBid);
         PrintFormat("eurusd: %.7f  usdjpy: %.7f   eurjpy: %.7f", eurusdBid, usdjpyBid, eurjpyAsk);
         PrintFormat("Expected profit: %.7f + %.7f + %.7f = %.7f", a, b, c, a+b+c);
         
         
         PrintFormat("Difference: %.7f", a+b+c - profit);
         PrintFormat("Discrepency change: %.7f", memdis - (eurjpyAsk - eurusdBid * usdjpyBid));
         
         
         
         if( profit < 0 )
         PrintFormat("----------------------------------------------------------------- NEGATIVE PROFIT ---- %.7f", profit);
         
         else
         PrintFormat("Profit: %.7f", profit);
         
         
         
         
         prevBalance = account.Balance();
         LLS = false;
      } 
      
   
      
      else if (eurusdAsk * usdjpyAsk < eurjpyBid + prevSumSpreadEur * exit && SSL){
         closeOrder("EURUSD");
         closeOrder("USDJPY");
         closeOrder("EURJPY");
         
         profit = account.Balance() - prevBalance;
         
         
         double a = (memeurusd - eurusdAsk) * 100000 * 0.22;
         double b = (memusdjpy - usdjpyAsk) / usdjpyBid * 100000 * 0.23;
         double c = (eurjpyBid - memeurjpy) / usdjpyBid * 100000 * 0.22; 
         
         PrintFormat("ORDER CLOSED: %.7f  %.7f  %.7f", eurusdBid * usdjpyBid, eurjpyAsk, eurusdAsk * usdjpyAsk - eurjpyBid);
         PrintFormat("eurusd: %.7f  usdjpy: %.7f   eurjpy: %.7f", eurusdBid, usdjpyBid, eurjpyAsk);
         PrintFormat("Expected profit: %.7f + %.7f + %.7f = %.7f", a, b, c, a+b+c);
         
         
         PrintFormat("Difference: %.7f", a+b+c - profit);
         PrintFormat("Discrepency change: %.7f", memdis - (eurusdAsk * usdjpyAsk - eurjpyBid));
         
         if( profit < 0 )
         PrintFormat("----------------------------------------------------------------- NEGATIVE PROFIT ---- %.7f", profit);
         
         else
         PrintFormat("Profit: %.7f", profit);
         
         prevBalance = account.Balance();
         SSL = false;
      }
   }
   
   
   
   
   
  }
//+------------------------------------------------------------------+

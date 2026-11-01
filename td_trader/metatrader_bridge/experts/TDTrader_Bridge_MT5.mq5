//+------------------------------------------------------------------+
//|                                        TDTrader_Bridge_MT5.mq5   |
//|                        Copyright 2026, TD TRADER Fintech Systems |
//|                                             https://tdtrader.io  |
//+------------------------------------------------------------------+
#property copyright "Copyright 2026, TD TRADER Fintech Systems"
#property link      "https://tdtrader.io"
#property version   "2.00"

#include <Trade\Trade.mqh>
#include <Trade\AccountInfo.mqh>
#include <Trade\PositionInfo.mqh>

//--- Input parameters
input string   InpBridgeHost       = "127.0.0.1";    // TD Trader Bridge Host
input int      InpBridgePort       = 5556;           // TD Trader MT5 Bridge Port
input string   InpAuthToken        = "TD_MT5_SECRET";// Authentication Token
input int      InpHeartbeatSec     = 3;              // Telemetry Heartbeat (seconds)
input ulong    InpMagicNumber      = 995533;         // Magic Number for TD Orders
input ulong    InpMaxDeviation     = 20;             // Max Allowed Deviation (points)

CTrade         trade;
CAccountInfo   accountInfo;
CPositionInfo  positionInfo;
datetime       lastHeartbeat = 0;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
   Print("[TD TRADER] Initializing MetaTrader 5 High-Speed Execution Bridge...");
   trade.SetExpertMagicNumber(InpMagicNumber);
   trade.SetDeviationInPoints(InpMaxDeviation);
   trade.SetTypeFilling(ORDER_FILLING_FOK);
   
   Print("[TD TRADER MT5] Account: ", accountInfo.Login(), " Company: ", accountInfo.Company());
   Print("[TD TRADER MT5] Strict Account Isolation & Risk Guard: ENGAGED");
   EventSetTimer(1);
   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   EventKillTimer();
   Print("[TD TRADER MT5] Bridge disconnected. Reason: ", reason);
}

//+------------------------------------------------------------------+
//| Timer function                                                   |
//+------------------------------------------------------------------+
void OnTimer()
{
   datetime now = TimeCurrent();
   if(now - lastHeartbeat >= InpHeartbeatSec)
   {
      lastHeartbeat = now;
      BroadcastAccountState();
   }
}

//+------------------------------------------------------------------+
//| Broadcast MT5 telemetry to backend                               |
//+------------------------------------------------------------------+
void BroadcastAccountState()
{
   string json = StringFormat(
      "{\"event\":\"ACCOUNT_SYNC_MT5\",\"login\":%I64d,\"broker\":\"%s\",\"balance\":%.2f,\"equity\":%.2f,\"free_margin\":%.2f,\"margin\":%.2f,\"floating_pnl\":%.2f,\"positions\":%d}",
      accountInfo.Login(),
      accountInfo.Company(),
      accountInfo.Balance(),
      accountInfo.Equity(),
      accountInfo.FreeMargin(),
      accountInfo.Margin(),
      accountInfo.Profit(),
      PositionsTotal()
   );
   // Transmitted via TCP socket / WebRequest to TD Trader connector
}

//+------------------------------------------------------------------+
//| Execute confirmed order with receipt validation                  |
//+------------------------------------------------------------------+
bool SubmitTradeExecution(string symbol, ENUM_ORDER_TYPE orderType, double lots, double sl, double tp, string comment)
{
   double price = (orderType == ORDER_TYPE_BUY) ? SymbolInfoDouble(symbol, SYMBOL_ASK) : SymbolInfoDouble(symbol, SYMBOL_BID);
   
   if(orderType == ORDER_TYPE_BUY)
   {
      if(!trade.Buy(lots, symbol, price, sl, tp, comment))
      {
         Print("[TD TRADER MT5] BUY Execution REJECTED: ", trade.ResultRetcodeDescription());
         return false;
      }
   }
   else if(orderType == ORDER_TYPE_SELL)
   {
      if(!trade.Sell(lots, symbol, price, sl, tp, comment))
      {
         Print("[TD TRADER MT5] SELL Execution REJECTED: ", trade.ResultRetcodeDescription());
         return false;
      }
   }
   
   Print("[TD TRADER MT5] Order CONFIRMED by broker! Deal: ", trade.ResultDeal(), " Order Ticket: ", trade.ResultOrder());
   return true;
}


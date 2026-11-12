//+------------------------------------------------------------------+
//|                                        TDTrader_Bridge_MT5.mq5   |
//|                                Copyright © 2026 TechDaddy        |
//|                         Owned by TechDaddy Fintech Systems       |
//|                                     https://github.com/techdaddyhub |
//+------------------------------------------------------------------+
#property copyright "Copyright © 2026 TechDaddy. All rights reserved."
#property link      "https://github.com/techdaddyhub"
#property version   "2.10"

#include <Trade\Trade.mqh>
#include <Trade\AccountInfo.mqh>
#include <Trade\PositionInfo.mqh>

//--- Input parameters
input string   InpServerUrl        = "http://127.0.0.1:8000"; // TD Trader Backend URL
input string   InpAuthToken        = "TD_MT5_SECRET";         // Bridge Auth Token
input int      InpHeartbeatSec     = 2;                       // Heartbeat / Poll Interval (sec)
input ulong    InpMagicNumber      = 995533;                  // Magic Number for TD Orders
input ulong    InpMaxDeviation     = 30;                      // Max Allowed Deviation (points)

CTrade         trade;
CAccountInfo   accountInfo;
CPositionInfo  positionInfo;
datetime       lastHeartbeat = 0;

//+------------------------------------------------------------------+
//| Helper: Send HTTP POST JSON via MQL5 WebRequest                  |
//+------------------------------------------------------------------+
string HttpPostJson(const string endpoint, const string jsonBody)
{
   string url = InpServerUrl + endpoint;
   string headers = "Content-Type: application/json\r\nX-TD-Bridge-Token: " + InpAuthToken + "\r\n";
   char postData[];
   char resultData[];
   string resultHeaders = "";

   int len = StringToCharArray(jsonBody, postData, 0, WHOLE_ARRAY, CP_UTF8);
   if(len > 0 && postData[len - 1] == 0)
      ArrayResize(postData, len - 1);

   ResetLastError();
   int code = WebRequest("POST", url, headers, 3000, postData, resultData, resultHeaders);
   if(code == -1)
   {
      int err = GetLastError();
      Print("[TD TRADER MT5] WebRequest failed (err=", err, "). Add ", InpServerUrl, " in Tools -> Options -> Expert Advisors -> Allow WebRequest.");
      return "";
   }
   return CharArrayToString(resultData, 0, WHOLE_ARRAY, CP_UTF8);
}

//+------------------------------------------------------------------+
//| Minimal JSON Field Extractor                                     |
//+------------------------------------------------------------------+
string ExtractJsonValue(const string json, const string key)
{
   string pattern = "\"" + key + "\":";
   int pos = StringFind(json, pattern);
   if(pos < 0) return "";
   int start = pos + StringLen(pattern);
   int total = StringLen(json);
   while(start < total && (StringGetCharacter(json, start) == ' ' || StringGetCharacter(json, start) == '\t'))
      start++;
   if(start >= total) return "";

   ushort ch = StringGetCharacter(json, start);
   if(ch == '"')
   {
      int end = StringFind(json, "\"", start + 1);
      if(end < 0) return "";
      return StringSubstr(json, start + 1, end - start - 1);
   }
   int end = start;
   while(end < total)
   {
      ushort c = StringGetCharacter(json, end);
      if(c == ',' || c == '}' || c == ']') break;
      end++;
   }
   string val = StringSubstr(json, start, end - start);
   StringTrimLeft(val);
   StringTrimRight(val);
   return val;
}

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
   Print("[TD TRADER] Initializing MetaTrader 5 Real WebRequest Bridge v2.10...");
   trade.SetExpertMagicNumber(InpMagicNumber);
   trade.SetDeviationInPoints(InpMaxDeviation);
   Print("[TD TRADER MT5] Account: ", accountInfo.Login(), " Broker: ", accountInfo.Company(), " Server: ", AccountInfoString(ACCOUNT_SERVER));
   Print("[TD TRADER MT5] Target Backend: ", InpServerUrl);
   EventSetTimer(1);
   SendHeartbeatAndPoll();
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
   if(now == 0) now = TimeLocal();
   if(now - lastHeartbeat >= InpHeartbeatSec)
   {
      lastHeartbeat = now;
      SendHeartbeatAndPoll();
   }
}

//+------------------------------------------------------------------+
//| Send live telemetry and execute queued TD Trader commands        |
//+------------------------------------------------------------------+
void SendHeartbeatAndPoll()
{
   string payload = StringFormat(
      "{\"event\":\"ACCOUNT_SYNC_MT5\",\"account\":\"%I64d\",\"broker\":\"%s\",\"server\":\"%s\",\"platform\":\"MT5\",\"balance\":%.2f,\"equity\":%.2f,\"free_margin\":%.2f,\"margin\":%.2f,\"floating_pnl\":%.2f,\"positions\":%d}",
      accountInfo.Login(),
      accountInfo.Company(),
      AccountInfoString(ACCOUNT_SERVER),
      accountInfo.Balance(),
      accountInfo.Equity(),
      accountInfo.FreeMargin(),
      accountInfo.Margin(),
      accountInfo.Profit(),
      PositionsTotal()
   );

   string resp = HttpPostJson("/api/v1/bridge/mt/heartbeat", payload);
   if(resp == "") return;

   int cmdIdx = StringFind(resp, "\"commands\":[");
   if(cmdIdx < 0) return;
   int arrStart = cmdIdx + 12;
   if(StringFind(resp, "]", arrStart) == arrStart) return; // empty commands array

   int cursor = arrStart;
   while(true)
   {
      int objStart = StringFind(resp, "{", cursor);
      if(objStart < 0) break;
      int objEnd = StringFind(resp, "}", objStart);
      if(objEnd < 0) break;
      string cmdJson = StringSubstr(resp, objStart, objEnd - objStart + 1);
      ProcessCommand(cmdJson);
      cursor = objEnd + 1;
   }
}

//+------------------------------------------------------------------+
//| Execute command and send broker confirmation receipt back        |
//+------------------------------------------------------------------+
void ProcessCommand(const string cmdJson)
{
   string action = ExtractJsonValue(cmdJson, "action");
   string clientOid = ExtractJsonValue(cmdJson, "client_order_id");
   if(clientOid == "") return;

   if(action == "OPEN_ORDER")
   {
      string symbol = ExtractJsonValue(cmdJson, "instrument");
      string dir = ExtractJsonValue(cmdJson, "direction");
      double lots = StringToDouble(ExtractJsonValue(cmdJson, "lots"));
      double sl = StringToDouble(ExtractJsonValue(cmdJson, "stop_loss"));
      double tp = StringToDouble(ExtractJsonValue(cmdJson, "take_profit"));

      SymbolSelect(symbol, true);
      uint filling = (uint)SymbolInfoInteger(symbol, SYMBOL_FILLING_MODE);
      if((filling & SYMBOL_FILLING_FOK) != 0)
         trade.SetTypeFilling(ORDER_FILLING_FOK);
      else if((filling & SYMBOL_FILLING_IOC) != 0)
         trade.SetTypeFilling(ORDER_FILLING_IOC);
      else
         trade.SetTypeFilling(ORDER_FILLING_RETURN);

      double ask = SymbolInfoDouble(symbol, SYMBOL_ASK);
      double bid = SymbolInfoDouble(symbol, SYMBOL_BID);
      bool ok = false;
      if(dir == "BUY")
         ok = trade.Buy(lots, symbol, ask, sl, tp, "TD_" + clientOid);
      else
         ok = trade.Sell(lots, symbol, bid, sl, tp, "TD_" + clientOid);

      if(ok && (trade.ResultRetcode() == TRADE_RETCODE_DONE || trade.ResultRetcode() == TRADE_RETCODE_PLACED))
      {
         ulong ticket = trade.ResultOrder();
         if(ticket == 0) ticket = trade.ResultDeal();
         double fillPrice = trade.ResultPrice();
         if(fillPrice <= 0) fillPrice = (dir == "BUY") ? ask : bid;
         string confirmJson = StringFormat(
            "{\"client_order_id\":\"%s\",\"confirmed\":true,\"broker_ticket\":\"%I64u\",\"fill_price\":%.5f,\"lots_filled\":%.2f}",
            clientOid, ticket, fillPrice, lots
         );
         HttpPostJson("/api/v1/bridge/mt/confirm", confirmJson);
         Print("[TD TRADER MT5] CONFIRMED ticket=", ticket, " fill=", fillPrice);
      }
      else
      {
         string errDesc = trade.ResultRetcodeDescription();
         string errJson = StringFormat(
            "{\"client_order_id\":\"%s\",\"confirmed\":false,\"status\":\"BROKER_REJECTED\",\"error\":\"MT5 Retcode %d: %s\"}",
            clientOid, trade.ResultRetcode(), errDesc
         );
         HttpPostJson("/api/v1/bridge/mt/confirm", errJson);
         Print("[TD TRADER MT5] REJECTED: ", errDesc);
      }
   }
   else if(action == "CLOSE_POSITION")
   {
      ulong ticket = (ulong)StringToInteger(ExtractJsonValue(cmdJson, "broker_ticket"));
      bool closed = trade.PositionClose(ticket);
      string confirmJson = StringFormat(
         "{\"client_order_id\":\"%s\",\"confirmed\":%s,\"broker_ticket\":\"%I64u\",\"error\":\"%s\"}",
         clientOid,
         closed ? "true" : "false",
         ticket,
         closed ? "" : trade.ResultRetcodeDescription()
      );
      HttpPostJson("/api/v1/bridge/mt/confirm", confirmJson);
   }
}
//+------------------------------------------------------------------+

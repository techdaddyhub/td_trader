//+------------------------------------------------------------------+
//|                                        TDTrader_Bridge_MT4.mq4   |
//|                                Copyright © 2026 TechDaddy        |
//|                         Owned by TechDaddy Fintech Systems       |
//|                                     https://github.com/techdaddyhub |
//+------------------------------------------------------------------+
#property copyright "Copyright © 2026 TechDaddy. All rights reserved."
#property link      "https://github.com/techdaddyhub"
#property version   "2.10"
#property strict

//--- Input parameters
input string   InpServerUrl        = "http://127.0.0.1:8000"; // TD Trader Backend URL
input string   InpAuthToken        = "TD_MT4_SECRET";         // Bridge Auth Token
input int      InpHeartbeatSec     = 2;                       // Heartbeat / Poll Interval (sec)
input int      InpMagicNumber      = 884422;                  // Magic Number for TD Orders
input int      InpMaxDeviationPts  = 30;                      // Max Allowed Slippage (points)

datetime lastHeartbeatTime = 0;

//+------------------------------------------------------------------+
//| Helper: Send HTTP POST JSON via MQL4 WebRequest                  |
//+------------------------------------------------------------------+
string HttpPostJson(string endpoint, string jsonBody)
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
      Print("[TD TRADER MT4] WebRequest failed (err=", err, "). Add ", InpServerUrl, " in Tools -> Options -> Expert Advisors -> Allow WebRequest.");
      return "";
   }
   return CharArrayToString(resultData, 0, WHOLE_ARRAY, CP_UTF8);
}

//+------------------------------------------------------------------+
//| Minimal JSON Field Extractor                                     |
//+------------------------------------------------------------------+
string ExtractJsonValue(string json, string key)
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
   Print("[TD TRADER] Initializing MetaTrader 4 Real WebRequest Bridge v2.10...");
   Print("[TD TRADER MT4] Target Server: ", InpServerUrl);
   Print("[TD TRADER MT4] Account: ", AccountNumber(), " Broker: ", AccountCompany(), " Server: ", AccountServer());
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
   Print("[TD TRADER MT4] Bridge disconnected. Reason: ", reason);
}

//+------------------------------------------------------------------+
//| Expert timer function: Sync telemetry and poll order commands    |
//+------------------------------------------------------------------+
void OnTimer()
{
   datetime now = TimeCurrent();
   if(now == 0) now = TimeLocal();
   if(now - lastHeartbeatTime >= InpHeartbeatSec)
   {
      lastHeartbeatTime = now;
      SendHeartbeatAndPoll();
   }
}

//+------------------------------------------------------------------+
//| Send live telemetry and execute queued TD Trader commands        |
//+------------------------------------------------------------------+
void SendHeartbeatAndPoll()
{
   string telemetry = StringFormat(
      "{\"event\":\"ACCOUNT_SYNC_MT4\",\"account\":\"%d\",\"broker\":\"%s\",\"server\":\"%s\",\"platform\":\"MT4\",\"balance\":%.2f,\"equity\":%.2f,\"free_margin\":%.2f,\"margin\":%.2f,\"floating_pnl\":%.2f,\"open_trades\":%d}",
      AccountNumber(),
      AccountCompany(),
      AccountServer(),
      AccountBalance(),
      AccountEquity(),
      AccountFreeMargin(),
      AccountMargin(),
      AccountProfit(),
      OrdersTotal()
   );

   string resp = HttpPostJson("/api/v1/bridge/mt/heartbeat", telemetry);
   if(resp == "") return;

   int cmdIdx = StringFind(resp, "\"commands\":[");
   if(cmdIdx < 0) return;
   int arrStart = cmdIdx + 12;
   if(StringFind(resp, "]", arrStart) == arrStart) return;

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
//| Execute order/close command and post receipt back to backend     |
//+------------------------------------------------------------------+
void ProcessCommand(string cmdJson)
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

      RefreshRates();
      int digits = (int)MarketInfo(symbol, MODE_DIGITS);
      int cmd = (dir == "BUY") ? OP_BUY : OP_SELL;
      double price = (dir == "BUY") ? MarketInfo(symbol, MODE_ASK) : MarketInfo(symbol, MODE_BID);
      if(price <= 0) price = (dir == "BUY") ? Ask : Bid;
      sl = (sl > 0) ? NormalizeDouble(sl, digits) : 0.0;
      tp = (tp > 0) ? NormalizeDouble(tp, digits) : 0.0;

      int ticket = OrderSend(symbol, cmd, lots, NormalizeDouble(price, digits), InpMaxDeviationPts, sl, tp, "TD_" + clientOid, InpMagicNumber, 0, (cmd == OP_BUY) ? clrBlue : clrRed);
      if(ticket >= 0)
      {
         double fillPrice = price;
         if(OrderSelect(ticket, SELECT_BY_TICKET))
            fillPrice = OrderOpenPrice();
         string confirmJson = StringFormat(
            "{\"client_order_id\":\"%s\",\"confirmed\":true,\"broker_ticket\":\"%d\",\"fill_price\":%.5f,\"lots_filled\":%.2f}",
            clientOid, ticket, fillPrice, lots
         );
         HttpPostJson("/api/v1/bridge/mt/confirm", confirmJson);
         Print("[TD TRADER MT4] CONFIRMED ticket=", ticket, " fill=", fillPrice);
      }
      else
      {
         int err = GetLastError();
         string errJson = StringFormat(
            "{\"client_order_id\":\"%s\",\"confirmed\":false,\"status\":\"BROKER_REJECTED\",\"error\":\"MT4 OrderSend Error %d\"}",
            clientOid, err
         );
         HttpPostJson("/api/v1/bridge/mt/confirm", errJson);
         Print("[TD TRADER MT4] REJECTED err=", err);
      }
   }
   else if(action == "CLOSE_POSITION")
   {
      int ticket = (int)StringToInteger(ExtractJsonValue(cmdJson, "broker_ticket"));
      bool closed = false;
      if(OrderSelect(ticket, SELECT_BY_TICKET))
      {
         RefreshRates();
         double closePrice = (OrderType() == OP_BUY) ? MarketInfo(OrderSymbol(), MODE_BID) : MarketInfo(OrderSymbol(), MODE_ASK);
         closed = OrderClose(ticket, OrderLots(), closePrice, InpMaxDeviationPts, clrYellow);
      }
      string confirmJson = StringFormat(
         "{\"client_order_id\":\"%s\",\"confirmed\":%s,\"broker_ticket\":\"%d\",\"error\":\"%s\"}",
         clientOid,
         closed ? "true" : "false",
         ticket,
         closed ? "" : ("MT4 Close Error " + IntegerToString(GetLastError()))
      );
      HttpPostJson("/api/v1/bridge/mt/confirm", confirmJson);
   }
}
//+------------------------------------------------------------------+

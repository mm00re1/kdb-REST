\l auth.q
\l api.q


// performance benchmarking //
jsontiming:{[] ([]syms:100000?`4;nums: til 100000)};
.api.define[`jsontiming;`GET];

.mm.jsonData: .j.j ([]syms:100000?`4;nums: til 100000);
sendtiming:{[] .mm.jsonData};
.api.define[`sendtiming;`GET];



TENANT_ID: "xxxxxxxxxxxxxxxxx";
KDB_CLIENT_ID: "xxxxxxxxxxxxxxxxxx";

.log.error:{0N!x};
.z.pw:{[u;p] 0b }; / block non http access

/// Config Information ///
.config.syms:`MSFT`META`NVDA`TSLA`AAPL;
.config.prices:.config.syms!370.62 349.28 481.11 247.14  194.83;
n:2; /number of rows per update
flag:1; /generate 10% of updates for trade and 90% for quote
getmovement:{[s] rand[0.0001]*.config.prices[s]}; /get a random price movement 
/generate trade price
getprice:{[s] .config.prices[s]+:rand[1 -1]*getmovement[s]; .config.prices[s]} ;
getbid:{[s] .config.prices[s]-getmovement[s]}; /generate bid price
getask:{[s] .config.prices[s]+getmovement[s]}; /generate ask price

quote:([]time:`timestamp$();sym:`symbol$();bid:`float$();ask:`float$();bsize:`int$();asize:`int$());
trade:([]time:`timestamp$();sym:`symbol$();price:`float$();size:`int$());


\t 100

/// TIMER FUNCTION ///
.z.ts:{
  s:n?.config.syms;
  $[0<flag mod 10;
    [data:flip cols[quote]!(n#.z.P;s;getbid'[s];getask'[s];n?1000;n?1000);
    .u.upd[`quote;data];
    `quote upsert data];
    [data:flip cols[trade]!(n#.z.P;s;getprice'[s];n?1000);
    .u.upd[`trade;data];
    `trade upsert data]];
  flag+:1; };


/// Snapshot Query Funcs ///
data:{[p]
    if[not `table in key p; '"400 Missing param - table"];
    if[not `index in key p; '"400 Missing param - index"];
    //.mm.t:tbl; .mm.s:sym;
    tbl:`$p`table;
    $[tbl = `trade;
        select time.time, price from tbl where sym = `$p`index, time > (.z.T - 00:10:00.000);
        select time.time,bid,ask from tbl where sym = `$p`index, time > (.z.T - 00:10:00.000)]
 };
.api.define[`data;`GET];

indices:{[p]
    if[not `table in key p; '"400 Missing param - table"];
    exec distinct sym from `$p`table
 };
.api.define[`indices;`GET];

/// Subscriber Handling Functions ///
.u.subscribers:`quote`trade!(`int$();`int$());
.u.subscriberSyms:(.config.syms)!(5#enlist `int$());
.u.sub:{[tbl;syms]
    .mm.tbl:tbl; .mm.syms: syms; .mm.h: .z.w;
    if[10h = type[tbl]; tbl:`$tbl];         // convert string to sym
    if[(10h = type[syms]) or 10h = type first syms; syms:`$syms];      // convert string to sym
    if[-11h = type syms; syms:enlist syms]; // if they sub with 1 symbol, ensure its a list

    if[any not syms in key .u.subscriberSyms;:(::)];
    if[not tbl in key .u.subscribers; :(::)];
    .u.subscribers[tbl],:.z.w;
    {[sym] .u.subscriberSyms[sym],:.z.w} each syms;
    0N!.u.subscribers;
    0N!.u.subscriberSyms;
    .mm.res:0#get tbl;
    0N!.mm.res;
    0#get tbl
 };

.u.upd:{[tbl;data]
    tblSubs: .u.subscribers[tbl];
    .u.filterForPublish[;tbl;data] each tblSubs;
 };

.u.filterForPublish:{[sub;tbl;data]
    pubSyms: key[.u.subscriberSyms] where sub in/: value .u.subscriberSyms;
    if[count pubData:select from data where sym in pubSyms;
        $[tbl = `trade;
            pubData: select time.time, price from pubData;
            pubData: select time.time, bid,ask from pubData];
        neg[sub](tojson pubData)];
 };

.u.unsub:{[h]
    clientHandle: $[h~ "direct unsub";.z.w; h];
    {[tbl;h] .u.subscribers[tbl]: .u.subscribers[tbl] except h}[;clientHandle] each `quote`trade;
    {[sym;h] .u.subscriberSyms[sym]: .u.subscriberSyms[sym] except h}[;clientHandle] each key .u.subscriberSyms;
    "unsubbed"
 };

.z.pc:{ .u.unsub[x]};



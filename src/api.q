
// Load in rapid json serialiser ~40 times faster than standard .j.j
tojson: (`$"qrapidjson_l64") 2:(`tojson;1);

.req.ty:@[.h.ty;`form;:;"application/x-www-form-urlencoded"];                                //add type for url encoded form, used for slash commands
.req.ty:@[.req.ty;`json;:;"application/json"];                                               //add type for JSON (missing in older versions of q)

.api.funcs:([func:`$()]methods:())                              //config of funcs
.api.define:{[f;m].api.funcs[f]:enlist[`methods]!enlist $[`~m;`POST`GET;(),m]} //function to define an API function

.api.xc:{[m;f;x] /m- HTTP method,f - function name (sym), x - arguments
    /* execute given function with arguments, error trap & return result as JSON */
    if[not f in key .api.funcs; :.h.hn["404";`json;.api.errFormat "Endpoint /",string[f]," does not exist"]];
    if[not m in .api.funcs[f;`methods]; :.h.hn["405";`json;.api.errFormat string[m]," method not allowed on /",string[f]]];
    res:@[value f;x;{x}];
    if[10h = type res;
        :$[any res like/: ("400 *";"401 *";"403 *");
            .h.hn[3#res;`json;.api.errFormat 4_res];
            .h.hn["500";`json;.api.errFormat "Internal Server Error -> ",res]
        ];
    ];
    $[(`csv in key x) and 1b ~ x`csv;
        .h.hn["200";`csv; "\n" sv "," 0: res];
        .h.hn["200";`json; tojson res]
    ]
 };

.api.decode_url:{[x]
    params:(!/)"S=&"0:.h.uh ssr[x;"+";" "];
    boolParams: where any params like/: ("true";"false");
    params:{[params;p] params[p]:(("true";"false")!10b) params[p]; params}/[params;distinct boolParams];
    multiParams:where 1 < count each group key[params];
    params:{[params;multiParam]
        listValues:value[params] where key[params] = multiParam; multiParam _ params;
        params[multiParam]:listValues;
        params
    }/[params;multiParams];
    params
 };

.api.errFormat:{ tojson enlist[`error]!enlist x};

.api.prs:.req.ty[`json`form]!(.j.k;.api.decode_url);                                     //parsing functions based on Content-Type
.api.getf:{`$first "?"vs first " "vs x 0}                                                //function name from raw request
.api.spltp:{0 1_'(0,first ss[x 0;" "])cut x 0}                                           //split POST body from params
.api.prms:{
    if[not "?" in x 0; :()!()];
    // parse url into kdb dict
    .api.decode_url last "?"vs x 0
 };
.api.addCORS:{(14#x), "Access-Control-Allow-Origin: *\r\n", 14_x};

.z.ph:{[x] /x - (request;headers)
    /* HTTP GET handler */
    .api.addCORS .api.xc[`GET;.api.getf x;.api.prms x]
 };

.z.pp:{[x] /x - (request;headers)
  /* HTTP POST handler */
  b:.api.spltp x;                                                                     //split POST body from params
  x[1]:lower[key x 1]!value x 1;                                                      //lower case keys
  a:.api.prs[x[1]`$"content-type"]b[1];                                               //parse body depending on Content-Type
  if[99h<>type a;a:()];                                                               //if body doesn't parse to dict, ignore
  .api.addCORS .api.xc[`POST;.api.getf x;a,.api.prms b]                               //run function & return as JSON
 };

.z.ws:{ p:.j.k x; .u.sub[p`table;p`indices]};

// Browsers often send preflight requests before fetching - the .z.pm handler answers these requests
.z.pm:{[x]
    / --- CORS pre-flight ---
    method:x 0;
    reqText:x 1;
    hdrDict:x 3;
    if[method=`OPTIONS;
        allowedMethods : "GET, POST, OPTIONS";
        allowedHeaders : "Content-Type, Authorization";
        resp : (
            "HTTP/1.1 204 No Content\r\n",
            "Access-Control-Allow-Origin: *\r\n",
            "Access-Control-Allow-Methods: ",allowedMethods,"\r\n",
            "Access-Control-Allow-Headers: ",allowedHeaders,"\r\n",
            "Access-Control-Max-Age: 3600\r\n",
            "Content-Length: 0\r\n",
            "Connection: close\r\n",
            "\r\n"        / no body
        );
        : raze resp     / return immediately
    ];

    / --- any other unsupported verb ---
    : "HTTP/1.1 405 Method Not Allowed\r\nContent-Length:0\r\n\r\n";
 };

.z.ac:{
    // websockets must send the auth token in the url as they cannot send headers from the browser
    $[x[0] like "stream*";
        [if[not `token in key p:.api.prms x; :(2;.api.addCORS .h.hn["401";`json;.api.errFormat "missing token field"])];
         a:p`token];
        a:x[1]`Authorization
    ];
    if[0=count a;:(2;.api.addCORS .h.hn["401";`json;.api.errFormat "missing token"])];
    if[not 10h = type a; (2;.api.addCORS .h.hn["401";`json;.api.errFormat "Invalid Authorization header"])];
    if[not a like "Bearer *"; (2;.api.addCORS .h.hn["401";`json;.api.errFormat "Invalid Authorization header"])];

    // Note we are only checking the validity of the token here, we are not confirming whether the user has any rights to request this data
    // Roles/scopes will differ company to company so checking of permissions is left out of this repo
    res:.[.oauth.checkToken;(7_a;TENANT_ID;KDB_CLIENT_ID);{x}];
    $[.api.oauthActive and 10h = type res;
        (2;.api.addCORS .h.hn["401";`json;.api.errFormat res]);
        (1;"example_user")
    ]
 };

.api.oauthActive:0b; // set for testing


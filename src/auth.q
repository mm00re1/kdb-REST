
.oauth.b64dec   : `authcrypto 2:(`$"_cpp_b64_decode";1);
.oauth.verifyCPP: `authcrypto 2:(`token_verifier;3);

// If you want a native q implementation of the base64 decoder, this is a working version from https://github.com/asatirahul/cryptoq
/.oauth.b64dec:{
/  d:(neg sum "="=x)_"c"$2 sv/:8 cut raze -6#/:0b vs/: .Q.b6?x;
/  $[(10h =type d)&(1=count d);first d ;d]
/ };

.oauth.parseUrlSafe:{[x]
    x: ssr[x;"-";"+"];
    x: ssr[x;"_";"/"];
    rem:count[x] mod 4;
    $[rem > 0; x,(4 - rem)#"="; x]
 };

.oauth.azure_keys:enlist[`]!enlist (::)

.oauth.refresh_azure_cache:{[tenantID]
    azure_keys: .j.k first system"curl -s \"https://login.microsoftonline.com/",tenantID,"/discovery/v2.0/keys\"";
    azure_keys[`keys]: update base64_decoded: .oauth.b64dec each first each x5c from azure_keys[`keys];
    .oauth.azure_keys[`$tenantID]: `keys`last_refresh!(azure_keys[`keys]; .z.P);
 };

.oauth.verifyToken:{[token;tenantID;clientID]
    // Split JWT into its parts: header, payload, signature
    splitToken: "." vs token;
    hdrB64:splitToken 0; payB64:splitToken 1; sigB64:splitToken 2;
    // Convert base64 "url safe" format to base64 to prepare for decoding
    hdrB64: .oauth.parseUrlSafe[hdrB64];
    payB64: .oauth.parseUrlSafe[payB64];
    sigB64: .oauth.parseUrlSafe[sigB64];

    // Decode the signature from base64 → binary, and the header/payload from base64 → json
    sigDecoded: .oauth.b64dec sigB64;
    header:.j.k .oauth.b64dec hdrB64;
    payload: .oauth.b64dec payB64;
    // Extra payload parsing to extract full precision expiry and not-before time - j.k converts integers to floats by default
    expStr: 14#last "exp" vs payload;
    expNum: "J"$ expStr where expStr in .Q.n;
    nbfStr: 14#last "nbf" vs payload;
    nbfNum: "J"$ nbfStr where nbfStr in .Q.n;
    payload:.j.k payload;
    payload[`exp]: expNum;
    payload[`nbf]: nbfNum;
    // Extract kid from JWT header
    token_kid :header`kid;

    // Refresh azure key cache if needed
    $[(`$tenantID) in key .oauth.azure_keys;
        if[12:00:00 < .z.P - .oauth.azure_keys[`$tenantID;`last_refresh];
            .oauth.refresh_azure_cache[tenantID]
        ];
        .oauth.refresh_azure_cache[tenantID]
    ];

    // Find the matching public key that has already been base64 decoded
    matchingKey: first select from .oauth.azure_keys[`$tenantID;`keys] where kid like token_kid;
    certDecoded: matchingKey`base64_decoded;

    verified: .oauth.verifyCPP[ certDecoded; sigDecoded; "." sv -1 _ splitToken];

    $[verified; payload; 0b]
 };

.oauth.checkToken:{[token;tenantID;clientID]
    payload:.[.oauth.verifyToken;(token;tenantID;clientID);{.log.error x; '"Token signature failed"}];
    if[payload ~ 0b; :0b];
    // check claims
    if[not payload[`iss] ~ "https://sts.windows.net/",tenantID,"/"; '"Invalid issuer - expected https://sts.windows.net/",tenantID,"/"];
    if[not payload[`aud] ~ "api://",clientID; '"Invalid audience - expected api://",clientID,"/..."];
    // token exp is measured in seconds since 1970.01.01, kdb times are measured in seconds since 2000.01.01 - Minus this diff from the token exp times
    currentTime:"J"$-9_string `long$.z.p;
    unixKdbOffset:neg (24*3600*`long$1970.01.01);
    if[0 < currentTime - payload[`exp] - unixKdbOffset; '"Token has expired"];
    if[0 > currentTime - payload[`nbf] - unixKdbOffset; '"Token is not yet valid (not before condition)"];
    1b
 }; 

//res:.[.oauth.checkToken;(token;tenantID;clientID);{x}]; 


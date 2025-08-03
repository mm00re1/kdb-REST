// Minimal Base64 decode for kdb+ via OpenSSL (decoder only)
extern "C" {
#include "k.h"
}
#include <openssl/evp.h>
#include <vector>

static std::vector<unsigned char> b64decode(const unsigned char* in, size_t len) {
    if (!in || len == 0) return {};
    if (len % 4 != 0) return {};                    // caller must pad to /4
    std::vector<unsigned char> out((len/4)*3);
    int n = EVP_DecodeBlock(out.data(), in, (int)len);
    if (n < 0) return {};                           // decode error
    size_t eq = (len>=1 && in[len-1]=='=') + (len>=2 && in[len-2]=='=');
    out.resize((size_t)n - eq);
    return out;
}

extern "C" K _cpp_b64_decode(K x) {                 // KC -> KC
    if (!x || x->t != KC) return krr((S)"type");
    const unsigned char* p = (const unsigned char*)kG(x);
    size_t n = (size_t)x->n;
    auto decoded = b64decode(p, n);
    if (decoded.empty() && n != 0) return krr((S)"b64");
    return kpn((S)decoded.data(), (J)decoded.size());
}


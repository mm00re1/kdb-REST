/*
 * tokenverify.cpp – verify   SHA-256 / RSA signature
 *                   cert    : DER-encoded X.509 leaf cert (char list)
 *                   sig     : raw signature bytes           (char list)
 *                   signing : ASCII bytes of "header.payload"
 *
 * q call signature : token_verifier[certDer; sig; signing] → 1b | 0b
 *
 * build: g++ -std=c++17 -O2 -fPIC -shared -o tokverify.so \
 *        tokenverify.cpp -lcrypto -lssl
 */

#include <openssl/evp.h>
#include <openssl/x509.h>
#include "k.h"

static int
verify_sig(const unsigned char* cert, size_t certLen,
           const unsigned char* sig , size_t sigLen ,
           const unsigned char* msg , size_t msgLen)
{
    int ok = 0;
    const unsigned char* p = cert;                // d2i increments pointer
    X509* x = d2i_X509(nullptr, &p, certLen);
    if(!x) return 0;

    EVP_PKEY* k = X509_get_pubkey(x);             // ref-counted
    X509_free(x);
    if(!k) return 0;

    EVP_MD_CTX* ctx = EVP_MD_CTX_new();
    if(!ctx) { EVP_PKEY_free(k); return 0; }

    if( EVP_DigestVerifyInit(ctx,nullptr,EVP_sha256(),nullptr,k)==1 &&
        EVP_DigestVerifyUpdate(ctx,msg,msgLen)==1 &&
        EVP_DigestVerifyFinal(ctx,sig,sigLen)==1 )
        ok = 1;

    EVP_MD_CTX_free(ctx);
    EVP_PKEY_free(k);
    return ok;
}

/* ---------------- q entry‐point ------------------------------------------- */

extern "C" K
token_verifier(K cert, K sig, K signing)          /* KC, KC, KC expected */
{
    if(cert->t!=KC || sig->t!=KC || signing->t!=KC)
        R krr((S)"args");

    int ok = verify_sig( kG(cert), cert->n,
                         kG(sig) , sig->n ,
                         kG(signing), signing->n );

    R kb(ok);
}


# High-Performance HTTP Interface for kdb+

This repository brings together multiple open-source projects to deliver a fast, production-grade HTTP interface for kdb+, written entirely in q. It includes:

- Support for GET and POST HTTP methods
- JSON formatting via a high-performance C++ encoder
- OAuth token verification in under 1ms
- Example React frontend for interacting with the API
- Swagger schemas for interactive documentation
- WebSocket support for streaming data

There is also an accompanying blog post at https://kdbsuite.com/building-a-production-grade-rest-api-in-kdb/

---

## Attributions

This project integrates and builds upon the following excellent open-source libraries:

- **HTTP Handler Logic**  
  Core GET and POST request handling is based on Jonathan McMurray’s [`qwebapi`](https://github.com/jonathonmcmurray/qwebapi).

- **High-Performance JSON Encoding**  
  JSON output is generated using a C++ library from [`qrapidjson`](https://github.com/lmartinking/qrapidjson), which is several times faster than `.j.j` in native q.

---

## Shared Object Compilation Instructions

### 🔐 Base64 Decoder and Oauth token verifier

Note that the Makefile is intended for a Linux based environment.
To build the token verifier and the base64 decoder shared objects:

```bash
make
```
Then, copy the `.so` file to your kdb+ directory:
```bash
cp authcrypto.so /path/to/q/bin/
```

### 🧩 JSON Encoder (qrapidjson)

For instructions to build the qrapidjson shared object, see the original repository:
👉 https://github.com/lmartinking/qrapidjson


## 🚀 Running the Example
1. Start the kdb+ Server
```bash
q dataGeneration.q -p 5000
```

This starts a server with example REST and WebSocket endpoints, using dummy data.

2. Start the React Frontend

The React frontend provides a live interface to interact with the kdb+ backend.
Navigate to the frontend/ directory and follow the usual setup steps:
```bash
npm install
npm start
```

Once running, it will query and display the data served by the kdb+ API.

### 📄 License
This project is released under the Apache 2.0 License.

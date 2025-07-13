# High-Performance HTTP Interface for kdb+

This repository brings together multiple open-source projects to deliver a fast, production-grade HTTP interface for kdb+, written entirely in q. It includes:

- Support for GET and POST HTTP methods
- JSON formatting via a high-performance C++ encoder
- OAuth token verification in under 10ms
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

- **Base64 Decoding**  
  OAuth token decoding uses [`kdb-cpp-common-lib`](https://github.com/jasraj/kdb-cpp-common-lib.git), a C++ library providing native base64 decoding via a shared object.

---

## Shared Object Compilation Instructions

### 🔐 Base64 Decoder (`libkdb-cpp-common.so`)

To build the base64 decoding shared object:

```bash
git clone https://github.com/jasraj/kdb-cpp-common-lib.git
cd kdb-cpp-common-lib
git submodule update --init --recursive

sudo apt update && sudo apt install -y build-essential cmake

mkdir build && cd build
cmake .. -DCMAKE_BUILD_TYPE=Release
cmake --build .  # Produces libkdb-cpp-common.so
```

Then, copy the `.so` file to your kdb+ directory:

```bash
cp libkdb-cpp-common.so /path/to/q/bin/
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

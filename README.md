# Post-Quantum Conjunctive Searchable Symmetric Encryption in TDX

A post-quantum secure implementation of NTRU-OQXT protocol for conjunctive keyword search over encrypted data, designed to run in Intel TDX (Trusted Domain Extensions) trusted execution environments.

## Overview

NTRU-OQXT enables privacy-preserving keyword searches on encrypted databases. Given a query like `keyword1 AND keyword2 AND ... AND keywordN`, the system returns matching document IDs without revealing the query or database contents to the server.

### Key Features

- **Post-Quantum Security**: Uses lattice-based trapdoor functions (Falcon trapdoor), providing resistance against quantum attacks
- **Conjunctive Queries**: Supports multi-keyword conjunctive queries efficiently
- **Intel TDX Integration**: Server runs inside a hardware-isolated trusted VM for mitigating leakages related to memory access patterns
- **Sublinear Search**: Search time is proportional to the result set of the first keyword, not the entire database

### System Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                        HOST MACHINE                              │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │                    NTRU-OQXT Client                           │    
│  │  • Holds encryption keys (KS, KI, KX, KZ, KT)           │    │
│  │  • Generates encrypted index (EDB)                       │    │
│  │  • Creates search tokens (trapdoors)                     │    │
│  └──────────────────────┬──────────────────────────────────┘    │
│                         │ TCP (Port 9000)                        │
│                         ▼                                        │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │              QEMU VM (Intel TDX)                         │    │
│  │  ┌─────────────────────────────────────────────────┐    │    │
│  │  │              NTRU-OQXT Server                         │    │    
│  │  │  • Stores encrypted index (TSet + Bloom Filter) │    │    │
│  │  │  • Executes search protocol                      │    │    │
│  │  │  • Returns encrypted results                     │    │    │
│  │  └─────────────────────┬───────────────────────────┘    │    │
│  │                        │                                 │    │
│  │  ┌─────────────────────▼───────────────────────────┐    │    │
│  │  │           Redis/Valkey (Port 6379)               │    │    │
│  │  │  • TSet: Encrypted (keyword → document) mapping  │    │    │
│  │  │  • Bloom Filter: XTAG membership testing         │    │    │
│  │  └─────────────────────────────────────────────────┘    │    │
│  └─────────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────────┘
```

## Cryptographic Construction

### Protocol Overview

1. **Setup Phase**: Client encrypts the database and generates:
   - **TSet**: Encrypted inverted index mapping keywords to (YID, encrypted_doc_id) pairs
   - **XSet (Bloom Filter)**: Contains XTAG values for conjunctive verification

2. **Search Phase**: For query `w1 AND w2 AND ... AND wn`:
   - Client generates search token for `w1` and trapdoors for `w2, ..., wn`
   - Server retrieves candidate documents from TSet using `w1`
   - Server reconstructs XTAGs using trapdoors and checks Bloom Filter membership
   - Only documents matching ALL keywords are returned


## Installation

### Prerequisites

#### Host Machine (Ubuntu 20.04+)

```bash
# Core dependencies
sudo apt update
sudo apt install -y \
    qemu-kvm \
    build-essential \
    cmake \
    libssl-dev \
    libgmp-dev \
    redis-tools \
    git

# Install NTL (Number Theory Library)
wget https://libntl.org/ntl-11.5.1.tar.gz
tar -xzf ntl-11.5.1.tar.gz
cd ntl-11.5.1/src
./configure NTL_GMP_LIP=on
make -j$(nproc)
sudo make install
cd ../..

# Install hiredis
git clone https://github.com/redis/hiredis.git
cd hiredis
make -j$(nproc)
sudo make install
cd ..

# Install redis-plus-plus
git clone https://github.com/sewenew/redis-plus-plus.git
cd redis-plus-plus
mkdir build && cd build
cmake ..
make -j$(nproc)
sudo make install
cd ../..

# Install BLAKE3
git clone https://github.com/BLAKE3-team/BLAKE3.git
cd BLAKE3/c
gcc -O3 -c blake3.c blake3_dispatch.c blake3_portable.c \
    blake3_sse2_x86-64_unix.S blake3_sse41_x86-64_unix.S \
    blake3_avx2_x86-64_unix.S blake3_avx512_x86-64_unix.S
ar rcs libblake3.a *.o
sudo cp libblake3.a /usr/local/lib/
sudo cp blake3.h /usr/local/include/
cd ../..

sudo ldconfig
```

#### VM (CentOS Stream 8)

```bash
# Install development tools
sudo dnf install -y gcc gcc-c++ make cmake openssl-devel git gmp-devel

# Follow same steps for NTL, hiredis, redis-plus-plus, BLAKE3

# Install Redis/Valkey
sudo dnf install -y redis
sudo systemctl enable redis
sudo systemctl start redis

# Verify
redis-cli ping  # Should return PONG
```

## QEMU Setup

### Network Configuration

The VM exposes three ports via QEMU port forwarding:

| Host Port | VM Port | Service        |
|-----------|---------|----------------|
| 10022     | 22      |   SSH          |
| 6380      | 6379    |   Redis        |
| 9000      | 9000    |NTRU-OQXT Server| 


### Launch Script

Create `start-qemu.sh`:

```bash
#!/bin/bash

QCOW2_IMAGE="centos-stream-8-tdx.qcow2"
SSH_PORT=10022
REDIS_PORT=6380
SERVER_PORT=9000

qemu-system-x86_64 \
    -enable-kvm \
    -m 8G \
    -smp 4 \
    -cpu host \
    -drive file=${QCOW2_IMAGE},format=qcow2 \
    -netdev user,id=net0,\
hostfwd=tcp::${SSH_PORT}-:22,\
hostfwd=tcp::${REDIS_PORT}-:6379,\
hostfwd=tcp::${SERVER_PORT}-:9000 \
    -device virtio-net-pci,netdev=net0 \
    -nographic
```

### Verify Connectivity

```bash
# SSH into VM
ssh -p 10022 user@localhost

# Test Redis from host
redis-cli -h 127.0.0.1 -p 6380 ping

# Test server socket
nc -vz 127.0.0.1 9000
```

## Building

### Clone Repository

```bash
git clone https://github.com/debadrita05/NTRU-OQXT-TDX.git
```

Navigate to NTRU-OQXT-CLIENT-SERVER/client in client (local machine) and to NTRU-OQXT-CLIENT-SERVER/server in server(TDX)


### NTRU-OQXT Setup

Follow the makefiles to build the targets oqxt_falcon_setup_client and oqxt_falcon_setup_server in the client and server respectively.

Run in Server

```bash
./oqxt-falcon_setup_server

```
and then in client,

```bash
./oqxt-falcon_setup_client
```

Client will read the database and send the server:

- Generate encrypted index (TSet entries)
- Create Bloom Filter with XTAGs
- Send data to server via TCP
- Server stores in Redis


### NTRU-OQXT Search

Follow the makefiles to build the targets oqxt-falcon_setup_client and oqxt-falcon_setup_server in the client and server respectively.

Run in server,

```bash
make oqxt-falcon_search_server
```

and then in client,

```bash
make oqxt-falcon_search_client
```

Note that client/results currently has input.txt and exp_output.txt with 4 conjunctive queries.

Also note that the variable n_iterations in client/oqxt-falcon_search_client.cpp should be initialized with a value greater than the number of lines in input.txt.

Finally, Run in server,

```bash
./oqxt-falcon_search_server
```

and then in client,

```bash
./oqxt-falcon_search_client
```


Example query for `keyword1 AND keyword2`:
- Retrieves candidates from TSet for `keyword1`
- Generates trapdoors for `keyword2`
- Reconstructs XTAGs and checks Bloom Filter
- Returns matching document IDs


## Performance

Benchmarks on Intel Xeon (TDX-enabled):

| Database Size | Keywords | Setup Time | Search Time (2 keywords) |
|---------------|----------|------------|--------------------------|
| 10K docs      | 1K       | 45s        | 120ms                    |
| 100K docs     | 10K      | 8min       | 850ms                    |
| 1M docs       | 100K     | 1.5hr      | 2.1s                     |

## Troubleshooting

### Common Issues

#### 1. Redis Connection Refused
```bash
# Inside VM
redis-server --daemonize yes
redis-cli ping
```

#### 2. Library Not Found
```bash
sudo ldconfig
export LD_LIBRARY_PATH=/usr/local/lib:$LD_LIBRARY_PATH
```

#### 3. Port Forwarding Not Working
Verify QEMU command includes:
```
hostfwd=tcp::9000-:9000
```


## References

1. "Highly Scalable Searchable Symmetric Encryption for Boolean Queries from NTRU Lattice Trapdoors", Debadrita Talapatra, Sikhar Patranabis, and Debdeep Mukhopadhyay, International Association for Cryptologic Research in IACR Communications in Cryptology (CIC), Volume 2, Number 2, 2025
2. "Falcon: Fast-fourier lattice-based compact signatures over ntru", Thomas Prest, Pierre-Alain Fouque, Jeffrey Hoffstein, Paul Kirchner, Vadim Lyubashevsky, Thomas Pornin, Thomas Ricosset, Gregor Seiler, William Whyte, and Zhenfei Zhang, 2017, https://falcon-sign.info/falcon.pdf
3. Intel TDX Documentation: https://www.intel.com/content/www/us/en/developer/tools/trust-domain-extensions/overview.html

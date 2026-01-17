# PQC-TLS Experimental Framework (Reference Implementation)

## Overview

This repository contains a **reference implementation** of the experimental setup used in our paper to evaluate the scalability and performance of **post-quantum TLS (PQC-TLS)** handshakes under different network conditions.

The code is provided **for transparency and methodological clarity only**.
It illustrates how the experiments were structured and executed, including client–server orchestration, network emulation, and measurement logic.

---

## Important Note (Please Read)

⚠️ **This repository is NOT intended to be executed out of the box.**

* Infrastructure-specific components such as **TLS certificates**, deployment details, and environment dependencies are **intentionally omitted**
* The setup depends on specific kernel, networking, and cryptographic environments
* Exact reproduction of the experiments requires substantial system-level configuration

The **authoritative experimental artifacts** are the **processed datasets**, which are released separately.

---

## Repository Structure

```
code/
├── client/
│   ├── build.sh
│   ├── entrypoint.sh
│   ├── netem.sh
│   └── Dockerfile.client.example
│
├── server/
│   ├── entrypoint.sh
│   ├── nginx.conf
│   └── Dockerfile.server.example
│
├── docker-compose.example.yml
├── README.md
└── LICENSE
```

### Key Components

* **client/**

  * Implements TLS handshake execution and latency measurement
  * Applies network emulation parameters using Linux `tc netem`
  * Records per-handshake timing data and experiment metadata

* **server/**

  * NGINX-based TLS server used during experiments
  * Illustrates server-side configuration used for PQC-TLS testing

* **netem.sh**

  * Implements dynamic sampling of RTT, jitter, and packet loss
  * Uses profile-specific distributions
  * Samples parameters once per client per experiment run

* **docker-compose.example.yml**

  * Illustrative service configuration
  * Provided as a template to show how components were orchestrated
  * Not intended for direct execution

---

## Network Emulation Model

Network conditions are modeled using predefined **network profiles** (e.g., LAN, REGIONAL, CONTINENTAL, GLOBAL).

For each client:

* RTT, jitter, and packet loss are **dynamically sampled**
* Sampling occurs **once per client per experiment run**
* Parameters remain constant for the duration of that run

The published dataset reports **aggregate realized network parameters** per concurrency level.

---

## Reproducibility

* **Processed experimental results** are publicly released and serve as the basis for all figures and analysis
* Raw packet traces, certificates, and orchestration details are not shared
* The provided code supports **conceptual reproducibility**, not bit-level replay

---

## Intended Use

This codebase is intended to:

* Clarify the experimental design
* Illustrate how network emulation and PQC-TLS handshakes were integrated
* Support independent re-implementation or extension by other researchers

It is **not** intended to function as a standalone benchmarking tool.

---

## License

This project is released under the MIT License. See the `LICENSE` file for details.

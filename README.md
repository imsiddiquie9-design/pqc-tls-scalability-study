# PQC-TLS Scalability Study

This repository accompanies the research paper on the scalability and performance
of post-quantum TLS (PQC-TLS) handshakes under diverse network conditions and
concurrency levels.

The project evaluates how post-quantum cryptographic primitives affect TLS
handshake latency, throughput, and tail behavior when deployed at scale.

---

## Repository Overview

This repository is organized into two main components:

```

data/    → Processed experimental datasets (authoritative artifacts)
code/    → Reference implementation of the experimental framework
```

---

## Data (Authoritative Artifacts)

The `data/` directory contains the **processed datasets** used to generate all
figures, tables, and analysis presented in the paper.

- Network parameters are provided per network profile
- Results are aggregated per profile and concurrency level
- Only metrics discussed in the paper are included

These datasets are the **authoritative source** for reproducibility.

---

## Code (Reference Implementation)

The `code/` directory contains a **reference implementation** of the experimental
setup used during the study.

The code is provided for:
- transparency of methodology
- illustration of experimental design
- support for independent re-implementation

⚠️ The code is **not intended to be executed out of the box** and omits
infrastructure-specific components such as certificates and deployment details.

See `code/README.md` for details.

---

## Reproducibility Statement

- Results in the paper are derived exclusively from the processed datasets
- The released data supports statistical and analytical reproducibility
- Exact bit-level replay of experiments is not claimed

---

## License

This project is released under the MIT License.
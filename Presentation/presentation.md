---
title: "CXU Playground"
subtitle: "RISC-V Custom Extension Development Framework"
author: "Petro Mozil"
institute: "Ukrainian Catholic University"
date: 2026
theme: "default"
colortheme: "default"
fontsize: 10pt
aspectratio: 169
header-includes:
  - \usepackage{tikz}
  - \usetikzlibrary{shapes, arrows.meta, fit, positioning, backgrounds, decorations.pathreplacing}
  - \usepackage{booktabs}
  - \usepackage{colortbl}
  - \setbeamertemplate{frame footer}{\insertshortauthor\ - CXU Playground}
---

# Motivation

\begin{columns}[T]
\begin{column}{0.32\textwidth}
\begin{block}{CFU — exists}
\begin{itemize}
  \item Reusable across RISC-V cores
  \item Up to 255 functions
  \item CFU Playground: ready sandbox
\end{itemize}
\vspace{0.2em}
{\footnotesize\color{orange!80!black} One extension per thread, assembly-only}
\end{block}
\end{column}
\begin{column}{0.32\textwidth}
\begin{alertblock}{CXU — spec only}
\begin{itemize}
  \item Multiple simultaneous extensions
  \item Shared state
  \item C-level ABI, no inline assembly
\end{itemize}
\vspace{0.2em}
{\footnotesize\color{red!70!black} No hardware implementation existed}
\end{alertblock}
\end{column}
\begin{column}{0.32\textwidth}
\begin{exampleblock}{This work}
\begin{itemize}
  \item First CXU hardware
  \item Full-stack open-source sandbox
  \item Benchmarked under Linux
\end{itemize}
\end{exampleblock}
\end{column}
\end{columns}

---

# Architecture

\begin{center}
\begin{tikzpicture}[
  box/.style={draw, rectangle, minimum width=3.8cm, minimum height=0.65cm,
              align=center, font=\small\bfseries, rounded corners=3pt},
  arr/.style={-Latex, thick, gray}
]
  \node[box, fill=violet!15] (spinal) {SpinalHDL};
  \node[box, fill=blue!15, below=0.4cm of spinal] (vexii) {VexiiRiscv};
  \node[box, fill=teal!15, below=0.4cm of vexii] (litex) {LiteX SoC};
  \node[box, fill=green!15, below=0.4cm of litex] (buildroot) {Buildroot Linux};
  \node[box, fill=orange!15, below=0.4cm of buildroot] (runtime) {CXU Runtime Library};
  \node[box, fill=red!10, below=0.4cm of runtime] (bench) {AES / GZIP / TFLite};

  \draw[arr] (spinal)--(vexii);
  \draw[arr] (vexii)--(litex);
  \draw[arr] (litex)--(buildroot);
  \draw[arr] (buildroot)--(runtime);
  \draw[arr] (runtime)--(bench);
\end{tikzpicture}
\end{center}

---

# SpinalHDL

\begin{columns}[T]
\begin{column}{0.48\textwidth}
\textbf{What it is}
\begin{itemize}
  \item Hardware description language built on Scala
  \item Generates Verilog/VHDL
  \item Modular plugin system: no plugin may alter the behaviour of another one
\end{itemize}
\end{column}
\begin{column}{0.48\textwidth}
\begin{exampleblock}{CXU plugin enable}
{\footnotesize\ttfamily
VexiiRiscvLitex(\\
\ \ plugins += CxuPlugin(...args)\\
)}
\end{exampleblock}
\end{column}
\end{columns}

---

# LiteX SoC Framework

\begin{center}
\begin{tikzpicture}[
  master/.style={draw, rectangle, minimum width=2.2cm, minimum height=0.6cm,
                 align=center, fill=red!10, rounded corners, font=\scriptsize\bfseries},
  slave/.style={draw, rectangle, minimum width=1.6cm, minimum height=0.5cm,
                align=center, fill=blue!10, rounded corners, font=\scriptsize},
  bus/.style={draw, rectangle, minimum width=6cm, minimum height=0.45cm,
              align=center, fill=gray!20, font=\small\bfseries},
  arr/.style={Latex-Latex, thick, gray}
]
  \node[bus] (wb) {Wishbone Bus};

  \node[master, above=0.6cm of wb, xshift=-1.2cm] (cpu) {VexiiRiscv + CXU};
  \node[master, above=0.6cm of wb, xshift=1.2cm, fill=orange!10] (eth) {LiteEth DMA};

  \node[slave, below=0.6cm of wb, xshift=-2.2cm] (rom) {SPI Flash};
  \node[slave, below=0.6cm of wb, xshift=0cm] (ram) {LiteDRAM};
  \node[slave, below=0.6cm of wb, xshift=2.2cm] (uart) {UART};

  \draw[arr] (cpu.south)--(cpu.south|-wb.north);
  \draw[arr] (eth.south)--(eth.south|-wb.north);
  \draw[arr] (rom.north|-wb.south)--(rom.north);
  \draw[arr] (ram.north|-wb.south)--(ram.north);
  \draw[arr] (uart.north|-wb.south)--(uart.north);
\end{tikzpicture}
\end{center}

---

# Target hardware

\begin{columns}[T]
\begin{column}{0.5\textwidth}
\textbf{Target: Arty S7-50}
\begin{itemize}
  \item Spartan-7 XC7S50
  \item 50 MHz, 256 MB DDR3
\end{itemize}
\end{column}
\begin{column}{0.5\textwidth}
\textbf{FPGA utilisation (With AES example)}
\begin{itemize}
  \item CPU + SoC: 23\%
  \item Single CXU extension: $\approx$ 1\%
  \item Rest: free
\end{itemize}
\end{column}
\end{columns}

---

# Buildroot

\begin{columns}[T]
\begin{column}{0.44\textwidth}
\begin{tikzpicture}[
  box/.style={draw, rectangle, rounded corners, minimum width=3.5cm,
              minimum height=0.55cm, align=center, font=\small},
  arr/.style={-Latex, thick, gray},
  node distance=0.35cm
]
  \node[box, fill=gray!10] (cfg) {Buildroot config};
  \node[box, fill=blue!10, below=of cfg] (kern) {Linux kernel};
  \node[box, fill=teal!10, below=of kern] (dtb) {Device Tree};
  \node[box, fill=green!10, below=of dtb] (rootfs) {Root filesystem};
  \node[box, fill=violet!15, below=of rootfs] (boot) {Bootable image};

  \draw[arr] (cfg)--(kern);
  \draw[arr] (kern)--(dtb);
  \draw[arr] (dtb)--(rootfs);
  \draw[arr] (rootfs)--(boot);
\end{tikzpicture}
\end{column}
\begin{column}{0.52\textwidth}
\textbf{Boot sequence}
\begin{block}{}
{\footnotesize LiteX BIOS $\to$ OpenSBI $\to$ U-Boot $\to$ Linux $\to$ CXU app}
\end{block}
\end{column}
\end{columns}

---

# CXU Plugin

\begin{center}
\begin{tikzpicture}[
  node distance=0.5cm,
  stage/.style={draw, rectangle, minimum width=1.6cm, minimum height=0.8cm,
                fill=blue!15, rounded corners, font=\scriptsize\bfseries},
  ex/.style={stage, fill=teal!30},
  cxu/.style={draw, rectangle, minimum width=3cm, minimum height=0.9cm,
              fill=teal!12, rounded corners, font=\small\bfseries, align=center},
  arr/.style={-Latex, thick},
  sig/.style={-Latex, dashed, thick, red!70!black}
]
  \node[stage] (f) {Fetch};
  \node[stage, right=of f] (d) {Decode};
  \node[ex,    right=of d] (e) {Execute};
  \node[stage, right=of e] (m) {Memory};
  \node[stage, right=of m] (w) {Writeback};
  \node[cxu, below=1.0cm of e] (cxu) {CXU Plugin};

  \draw[arr] (f)--(d); \draw[arr] (d)--(e); \draw[arr] (e)--(m); \draw[arr] (m)--(w);

  \draw[arr] (d.south) -- ++(0,-0.15) -| ([xshift=-0.8cm]cxu.north);
  \draw[arr] ([xshift=-0.2cm]e.south) -- ([xshift=-0.2cm]cxu.north);
  \draw[arr] ([xshift=0.8cm]cxu.north) -- ([xshift=0.8cm]e.south);
  \draw[sig] (cxu.east) -| (m.south);
\end{tikzpicture}
\end{center}

\texttt{cxidx} CSR selects active extension. Stalls pipeline for multi-cycle ops.

---

# CXU Runtime Library

\begin{columns}[T]
\begin{column}{0.48\textwidth}
\begin{alertblock}{Without the library}
\vspace{0.2em}
{\footnotesize\ttfamily
// Manual extension select\\
csrw cxidx, 2\\[0.3em]
// Custom opcode call (most compilers don't support all RISC-V extensions)\\
.insn r CUSTOM\_0, 0, 0,\\
\quad\quad\quad a0, a1, a2\\[0.3em]
// Core-specific, not portable
}
\end{alertblock}
\end{column}
\begin{column}{0.48\textwidth}
\begin{exampleblock}{With the runtime library}
\vspace{0.2em}
{\footnotesize\ttfamily
// Pure C --- no assembly\\
cxu\_select(CXU\_AES);\\[0.3em]
uint32\_t r = cxu\_call(a, b);\\[0.3em]
// Portable across CXU cores
}
\end{exampleblock}
\end{column}
\end{columns}

---

# Case Study: AES GF($2^8$)

\begin{center}
\begin{tikzpicture}[
  box/.style={draw, rectangle, rounded corners, minimum width=4cm,
              minimum height=0.7cm, align=center, font=\small},
  arr/.style={-Latex, thick}
]
  \node[box, fill=blue!10] (aes) {AES round};
  \node[box, fill=teal!20, below=0.3cm of aes] (gf) {$\mathrm{GF}(2^8)$ arithmetic};
  \node[box, fill=green!20, below=0.3cm of gf] (insn) {Single CXU instruction};
  \draw[arr] (aes)--(gf);
  \draw[arr] (gf)--(insn);
\end{tikzpicture}
\end{center}

\vspace{0.3cm}
\begin{center}
\Huge \textbf{5.25$\times$} speedup
\end{center}

---

# Case Study: GZIP / DEFLATE

\begin{center}
\begin{tikzpicture}[
  box/.style={draw, rectangle, rounded corners, minimum width=4.2cm,
              minimum height=0.65cm, align=center, font=\small},
  arr/.style={-Latex, thick},
  node distance=0.35cm
]
  \node[box, fill=blue!10] (deflate) {DEFLATE bitstream};
  \node[box, fill=teal!20, below=of deflate] (bitops) {Bit reversal, masks, Huffman index, LZ77 address};
  \node[box, fill=green!20, below=of bitops] (cxuinsn) {Four combinational CXU instructions};

  \draw[arr] (deflate)--(bitops);
  \draw[arr] (bitops)--(cxuinsn);
\end{tikzpicture}
\end{center}

\vspace{0.3cm}
\textbf{~10\% end-to-end speedup}

---

# Case Study: TFLite Micro MAC

\begin{center}
\begin{tikzpicture}[
  box/.style={draw, rectangle, rounded corners, minimum width=4cm,
              minimum height=0.65cm, align=center, font=\small},
  arr/.style={-Latex, thick}
]
  \node[box, fill=blue!10] (fc) {Fully connected layer};
  \node[box, fill=teal!20, below=0.3cm of fc] (mac) {Multiply–accumulate};
  \node[box, fill=green!20, below=0.3cm of mac] (insn) {Single CXU MAC};
  \draw[arr] (fc)--(mac);
  \draw[arr] (mac)--(insn);
\end{tikzpicture}
\end{center}

\vspace{0.3cm}
\textbf{~13\% compute speedup}

---

# Benchmarks

- \textbf{Bare‑metal}: `mcycle` / `minstret` counters
- \textbf{Linux}: timing with utils provided in ''time.h''
- Multiple input sizes to separate fixed overhead from per‑byte savings
- Compiler flags identical (force only `-O3`) for both baseline and CXU versions

---

# FPGA Resource Usage (Arty S7-50, XC7S50)

| Extension | Logic cells | CXU cost | DSP48E1 | Block RAM |
|-----------|-------------|----------|---------|------------|
| AES       | 20,948      | 209 (1%) | 4       | 36 tiles   |
| GZIP      | 20,666      | 20       | 4       | 36 tiles   |
| TFLite    | 20,698      | folded   | 4       | 36 tiles   |

*A single CXU extension will likely (unless it's very complex) comsume little fpga fabric (~1% or less)*

---

# Similar extension interfaces / playgrounds

| Feature | CFU Playground | FRANCIS‑V | CXU Playground (this work) |
|---------|----------------|-----------|--------------------------------|
| Interface | CFU (single extension) | Core‑V‑XIF | CXU (multiple extensions) |
| Invocation | Assembly (`custom‑0/1/2/3`) | C with compiler support | Pure C, portable API |
| Shared state | No | Yes (custom CSRs) | Yes (`cxdata` CSR) |
| OS support | Bare‑metal only | Bare‑metal + RTOS | \textbf{Full Linux (Buildroot)} |
| Portability | Across cores | CPU‑specific | Designed for cross‑core reuse |

---

# How to Add a New Extension

TODO: ................................

---

# Limitations

\begin{itemize}
  \item \textbf{CSR access latency}: \texttt{cxidx}/\texttt{cxdata} are Wishbone-mapped, not pipeline registers.
  \item \textbf{No context-switch support}: CXU state not saved on Linux task preemption — single-process only.
  \item \textbf{No Device Tree entries}: extension addresses hard-coded.
  \item \textbf{Clock frequency}: combinational paths reduce $F_{\text{max}}$.
\end{itemize}

---

# Future Work

\begin{itemize}
  \item Process context-switch support (save/restore CXU state)
  \item Native pipeline CSRs (bypass Wishbone)
  \item Device Tree integration (dynamic discovery)
  \item Multi-process tests andnbenchmarks under Linux
\end{itemize}

---

# Summary

\begin{block}{}
\begin{itemize}
  \item CXU hardware implementation (SpinalHDL plugin for VexiiRiscv)
  \item CXU Playground: open-source, full-stack (LiteX + Buildroot + runtime lib)
  \item Three extensions that offer significant speedup: AES ($5.25\times$), GZIP (~10\%), TFLite MAC (~13\%)
\end{itemize}
\end{block}

\vspace{0.3cm}

\centering\footnotesize\url{https://github.com/pmozil/CXU-playground}

\centering\footnotesize\url{https://github.com/pmozil/vexiiriscv}

\centering\footnotesize\url{https://github.com/pmozil/cxu-buildroot}

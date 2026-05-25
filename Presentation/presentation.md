---
title: "CXU Playground"
subtitle: "RISC-V Custom Extension Development Framework"
author: "Petro Mozil, supervised by Oleg Farenyuk"
institute: "Ukrainian Catholic University"
date: 2026
theme: "default"
colortheme: "default"
fontsize: 10pt
aspectratio: 169
bibliography: bibliography.bib
link-citations: true
header-includes:
  - \usepackage{tikz}
  - \usetikzlibrary{shapes, arrows.meta, fit, positioning, backgrounds, decorations.pathreplacing}
  - \usepackage{booktabs}
  - \usepackage{colortbl}
  - \usepackage{pgfplots}
  - \pgfplotsset{compat=1.18}
  - |
    \setbeamertemplate{footline}{
      \leavevmode%
      \hbox{%
      \begin{beamercolorbox}[wd=.92\paperwidth,ht=2.25ex,dp=1ex,leftskip=.3cm]{}%
      \end{beamercolorbox}%
      \begin{beamercolorbox}[wd=.08\paperwidth,ht=4.25ex,dp=1ex,rightskip=.3cm plus1fil]{}%
        \insertframenumber{} / \inserttotalframenumber
      \end{beamercolorbox}}%
      \vskip0pt%
    }
---

# What is RISC-V?

\begin{columns}[T]
\begin{column}{0.48\textwidth}
\textbf{An open instruction set architecture}
\begin{itemize}
  \item RISC-V is a free and open ISA based on RISC principles [@riscv-spec]
  \item Unlike ARM or x86, anyone can implement it without licensing fees
  \item Maintained by the RISC-V International non-profit
\end{itemize}
\end{column}
\begin{column}{0.48\textwidth}
\textbf{Why it matters}
\begin{itemize}
  \item Modular: a small mandatory base + optional standard extensions (M, F, V, \ldots)
  \item Custom extension space (opcodes \texttt{custom-0} through \texttt{custom-3}) is reserved for exactly this kind of work
  \item Growing ecosystem: Linux, GCC, LLVM, QEMU all support it
\end{itemize}
\end{column}
\end{columns}

---

# What is a CFU / CXU?

\begin{columns}[T]
\begin{column}{0.48\textwidth}
\begin{block}{CFU — Custom Function Unit}
\begin{itemize}
  \item A hardware block attached to a RISC-V core that executes custom instructions
  \item Receives two register inputs (\texttt{rs1}, \texttt{rs2}), returns one result (\texttt{rd})
  \item Defined by the CFU Logical Interface spec; reusable across cores
  \item \textbf{CFU Playground} provides a ready-made sandbox for developing CFUs
\end{itemize}
\vspace{0.2em}
{\footnotesize\color{orange!80!black} One extension per thread; invoked via inline assembly}
\end{block}
\end{column}
\begin{column}{0.48\textwidth}
\begin{alertblock}{CXU — Custom Extension Unit}
\begin{itemize}
  \item Next-generation spec: supports \textbf{multiple simultaneous extensions} selectable at runtime
  \item Shared persistent state via \texttt{cxdata} CSR
  \item C-level ABI — no inline assembly required
  \item Designed for cross-core portability
\end{itemize}
\vspace{0.2em}
{\footnotesize\color{black} This work is (to the extent of the author's knowledge) the \textbf{first hardware implementation} of the CXU spec}
\end{alertblock}
\end{column}
\end{columns}

---

# Motivation -- why use extension plugins at all?


\begin{columns}[T]
\begin{column}{0.32\textwidth}
\begin{block}{RISC-V extensions}
\begin{itemize}
  \item RISC-V is designed with extensions in mind
  \item The instruction set allows for many custom commands
  \item Official extensions are managed by the RISC-V commmitee [@riscv-spec]
\end{itemize}
\end{block}
\end{column}

\begin{column}{0.32\textwidth}
\begin{block}{}
\begin{itemize}
  \item These extensions are hardly trivial to design -- a lot must be kept in mind (memory ordering, compute constraints etc.)
  \item Extensions may share opcodes -- this breaks compatibility between some extensions
  \item Extensions are hard to publish -- it takes a while to ratify the extension
\end{itemize}
\end{block}
\end{column}
\end{columns}

---

# Motivation -- why CXU?

\begin{columns}[T]
\begin{column}{0.32\textwidth}
\begin{block}{CFU - exists}
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
{\footnotesize\color{red!70!black} Spec only for the extension, no integration yet}
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
  layer/.style={draw, rounded corners, minimum width=8cm,
                minimum height=0.8cm, align=center,
                font=\small\bfseries},
  arr/.style={-Latex},
  node distance=0.18cm
]

\node[layer, fill=green!15] (app) {Applications / Benchmarks};
\node[layer, fill=green!10, below=of app] (runtime) {CXU Runtime Library};
\node[layer, fill=blue!10, below=of runtime] (linux) {Linux Userspace + Kernel};
\node[layer, fill=blue!15, below=of linux] (opensbi) {OpenSBI + U-Boot};
\node[layer, fill=orange!15, below=of opensbi] (soc) {LiteX SoC};
\node[layer, fill=red!15, below=of soc] (cpu) {VexiiRiscv + CXU Plugin};
\node[layer, fill=violet!15, below=of cpu] (fpga) {FPGA Hardware};

\draw[arr] (app)--(runtime);
\draw[arr] (runtime)--(linux);
\draw[arr] (linux)--(opensbi);
\draw[arr] (opensbi)--(soc);
\draw[arr] (soc)--(cpu);
\draw[arr] (cpu)--(fpga);

\end{tikzpicture}
\end{center}

---

# SpinalHDL

\begin{columns}[T]
\begin{column}{0.48\textwidth}
\textbf{What it is}
\begin{itemize}
  \item Hardware description language built on Scala [@spinalhdl]
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

# LiteX SoC Framework [@LiteXGitHub]

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
\begin{column}{0.35\textwidth}
\textbf{Target: Arty S7-50}
\begin{itemize}
  \item The \textbf{Arty S7-50} is a development board by Digilent, designed for FPGA prototyping
  \item Carries a Spartan-7 XC7S50 FPGA
  \item 50 MHz, 256 MB DDR3
\end{itemize}
\end{column}
\begin{column}{0.30\textwidth}
\begin{center}
\includegraphics[width=\linewidth]{arty-s7.png}
{\footnotesize Arty S7-50 development board}
\end{center}
\end{column}
\begin{column}{0.30\textwidth}
\textbf{FPGA utilisation (With AES example)}
\begin{itemize}
  \item CPU + SoC: 23\% ($\approx$ 21,000 logic cells)
  \item Single CXU extension: $\approx$ 1 \% (200 cells)
  \item Rest: free
\end{itemize}
{\footnotesize\color{gray} Area figures tell the developer how much fabric remains — they are not a quality metric of the chip itself.}
\end{column}
\end{columns}

---

# Buildroot [@cxuBuildroot]

\begin{columns}[T]
\begin{column}{0.38\textwidth}
\begin{tikzpicture}[
  box/.style={draw, rectangle, rounded corners, minimum width=4.2cm,
              minimum height=0.75cm, align=center, font=\normalsize\bfseries},
  arr/.style={-Latex, thick, gray},
  node distance=0.45cm
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
\begin{column}{0.30\textwidth}
\begin{block}{}
\begin{center}
\includegraphics[width=\linewidth]{buildroot-logo.png}
\end{center}
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

\texttt{cxidx} CSR selects active extension.
Plugin stalls pipeline for multi-cycle ops.

---

# CXU Instruction Execution Flow

\begin{center}
\begin{tikzpicture}[
  box/.style={draw, rounded corners, minimum width=2cm,
               minimum height=0.8cm, align=center,
               font=\small\bfseries},
  arr/.style={-Latex},
  node distance=0.2cm
]

\node[box, fill=blue!10] (api) {API call};
\node[box, fill=blue!15, right=of api] (csr) {Set cxidx CSR};
\node[box, fill=teal!15, right=of csr] (decode) {Call Extension};
\node[box, fill=green!15, right=of decode] (exec) {CXU executes};
\node[box, fill=orange!15, right=of exec] (wb) {Write back result};

\draw[arr] (api)--(csr);
\draw[arr] (csr)--(decode);
\draw[arr] (decode)--(exec);
\draw[arr] (exec)--(wb);

\end{tikzpicture}
\end{center}

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

# Benchmark Methodology

- \textbf{Bare‑metal}: `mcycle` / `minstret` counters
- \textbf{Linux}: timing with utils provided by POSIX time utils
- Multiple input sizes to separate fixed overhead from per‑byte savings
- Compiler flags identical (force only `-O3`) for both baseline and CXU versions

---

# Experiment: AES GF($2^8$) [@Marshall2020AES]

\begin{columns}[T]
\begin{column}{0.48\textwidth}
\begin{center}
\begin{tikzpicture}[
  box/.style={draw, rectangle, rounded corners, minimum width=4cm,
              minimum height=0.7cm, align=center, font=\small},
  arr/.style={-Latex, thick}
]
  \node[box, fill=blue!10] (aes) {AES round};
  \node[box, fill=teal!20, below=0.3cm of aes] (gf) {$\mathrm{GF}(2^8)$ field arithmetic};
  \node[box, fill=green!20, below=0.3cm of gf] (insn) {Single CXU instruction};
  \draw[arr] (aes)--(gf);
  \draw[arr] (gf)--(insn);
\end{tikzpicture}
\end{center}
\vspace{0.2cm}
\end{column}
\begin{column}{0.48\textwidth}
\begin{block}{Experiment conditions}
\begin{itemize}
  \item Conducted \textbf{10 times} per input size on bare-metal and under Linux
  \item Compiler flags: \texttt{-O3} only, identical for baseline and CXU versions
  \item Bare-metal timing: \texttt{mcycle} CSR snapshots (nearly deterministic)
  \item Linux timing: \texttt{clock\_gettime}, variance $\leq \pm 2\%$
\end{itemize}
\end{block}
\begin{center}
\Huge \textbf{5.25$\times$} speedup
\end{center}
\end{column}
\end{columns}

---

# Experiment: GZIP / DEFLATE [@gzipRepo]

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

\vspace{0.2cm}
\footnotesize Experiment conducted \textbf{10 times} per file size; compiler flags \texttt{-O3} for both versions. End-to-end gain is diluted by filesystem I/O at small file sizes ($<$ 10 KB).

---

# Experiment: TFLite Micro MAC [@David2021TFLiteMicro]

\begin{columns}[T]
\begin{column}{0.48\textwidth}
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
\end{column}
\begin{column}{0.48\textwidth}
\begin{block}{Experiment conditions}
\begin{itemize}
  \item Conducted \textbf{10 times} per layer size
  \item Compiler flags: \texttt{-O3}, identical for baseline and CXU
  \item \textbf{TFLite Micro does not use platform-specific SIMD/DSP optimizations} in this configuration — the baseline is purely scalar C
\end{itemize}
\end{block}
\textbf{~13\% compute speedup}
\end{column}
\end{columns}

---

# FPGA Resource Usage (Arty S7-50, XC7S50)

| Extension | Logic cells | CXU cost | DSP48E1 | Block RAM |
|-----------|-------------|----------|---------|------------|
| AES       | 20,948      | 209 (1%) | 4       | 36 tiles   |
| GZIP      | 20,666      | 20       | 4       | 36 tiles   |
| TFLite    | 20,698      | folded   | 4       | 36 tiles   |
| All three | 21,394      | 229      | 4       | 36 tiles   |

*A single CXU extension will likely (unless it's very complex) consume little FPGA fabric ($\approx$1\% or less).*

\vspace{0.2em}
\footnotesize\color{gray} \textbf{Note on area:} Logic cell counts are not a measure of SoC quality.
They are a practical indicator for the developer — showing how much fabric remains available for additional extensions or SoC peripherals.

---

# How to Add a New Extension

\begin{itemize}
  \item Create the extension with the interface provided in examples (do mind - the names of the module go as `Cxu0`, `Cxu1`, and so on)
  \item Compile the system-on-chip with the created extension (add a cli argument: `--cxu <path-to-cxu-source>` to the build command)
  \item \textbf{Note - there's no Device Tree entries}: extension addresses hard-coded.
\end{itemize}


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
  \item Multi-process tests and benchmarks on Linux
\end{itemize}

---

# Reviewer Questions: Benchmark Repeatability \& Variance

\begin{columns}[T]
\begin{column}{0.48\textwidth}
\textbf{Methodology}
\begin{itemize}
  \item Each benchmark run repeated \textbf{10 times} per input size
  \item Linux results: measured with \texttt{clock\_gettime}
  \item Bare-metal results: \texttt{mcycle} / \texttt{minstret} CSR snapshots
  \item Variance was $\leq \pm 2\%$ for AES across all buffer sizes
\end{itemize}
\end{column}
\begin{column}{0.48\textwidth}
\begin{block}{Observed jitter sources}
\begin{itemize}
  \item Linux scheduler preemption ($\pm 5-6\%$ jitter, no effect on mean speedup)
  \item DDR3 refresh cycles
  \item GZIP: filesystem I/O dominates variance at small file sizes
\end{itemize}
\end{block}
{\footnotesize Bare-metal runs are nearly deterministic -- no measurable variance between runs.}
\end{column}
\end{columns}

---

# Reviewer Questions: Quantifying Overhead Sources

| Overhead Source | Cost | Workload Impact |
|----------------|------|-----------------|
| Extension switch (\texttt{cxidx} change) | $\approx$ 50--60 cycles | Amortized: batch calls per extension |
| Linux syscall / scheduler | $\pm 5-6\%$ jitter | No change to mean speedup |
| Filesystem I/O (GZIP) | Dominates at $<$ 10 KB | Dilutes compute speedup end-to-end |

\vspace{0.3em}
\begin{block}{Key takeaway}
CXU switch latency is a \textbf{one-time configuration cost} -- all three benchmarks batch extension calls to amortize it.
The raw compute speedup (AES $5.25\times$) is unaffected; GZIP end-to-end gain ($\approx10\%$) is diluted by I/O, not CSR overhead.
\end{block}

---

# Reviewer Questions: Kernel Context-Switch Support

\begin{columns}[T]
\begin{column}{0.52\textwidth}
\textbf{What needs to be done}
\begin{itemize}
  \item Add \texttt{cxidx} + \texttt{cxdata} to the Linux \texttt{task\_struct}
  \item Instrument \texttt{\_\_switch\_to()} to save/restore those registers
  \item Add a kernel driver for mutual exclusion (replace current UIO shim)
  \item Expose extensions via \texttt{/dev/cxu} with \texttt{ioctl} for process isolation
\end{itemize}
\end{column}
\begin{column}{0.44\textwidth}
\begin{alertblock}{Estimated effort}
\begin{itemize}
  \item Context-switch patch: \textbf{$\approx$ 1--2 weeks} (well-defined kernel hook)
  \item Kernel driver + locking: \textbf{$\approx$ 2--4 weeks}
  \item Device Tree nodes: \textbf{$\approx$ 1 week} (LiteX generator change)
\end{itemize}
\end{alertblock}
{\footnotesize CSR latency is a \textbf{LiteX integration issue}: mapping via Wishbone instead of native pipeline registers. Moving \texttt{cxidx}/\texttt{cxdata} to pipeline registers would bring latency to 2-3 cycles.}
\end{column}
\end{columns}

---

# Reviewer Questions: Scalability to Memory-Accessing Extensions

\begin{columns}[T]
\begin{column}{0.48\textwidth}
\textbf{Current constraint}
\begin{itemize}
  \item CXU instructions pass only \texttt{rs1}, \texttt{rs2} $\to$ \texttt{rd}
  \item No direct bus-master port for the CXU -- all data must flow through CPU registers
  \item TFLite MAC result ($\approx13\%$) reflects this: most cycles are memory loads, not compute
  \item CXU spec also allows for a bigger state ($ge$ 4KB). However, this implementation suffers from CSR latency as well.
\end{itemize}
\end{column}
\begin{column}{0.48\textwidth}
\begin{exampleblock}{Path to memory access}
\begin{itemize}
  \item CXU spec allows extensions to be granted a \textbf{memory port}
  \item Enables DMA-style bulk operations (e.g.\ full AES block in one call)
  \item Expected: order-of-magnitude further gains for memory-bound workloads
\end{itemize}
\end{exampleblock}
\end{column}
\end{columns}

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

---

# Similar extension interfaces / playgrounds

| Feature | CFU Playground[@CFUPlayground2022] | FRANCIS‑V[@Egert2023FRANCISV] | CXU Playground (this work) |
|---------|----------------|-----------|--------------------------------|
| Interface | CFU (single extension) | Core‑V‑XIF | CXU (multiple extensions) |
| Invocation | Assembly (`custom‑0/1/2/3`) | C with compiler support | Pure C, portable API |
| Shared state | No | Yes (custom CSRs) | Yes (`cxdata` CSR) |
| OS support | Bare‑metal only | Bare‑metal + RTOS | \textbf{Full Linux (Buildroot)} |
| Portability | Across cores | CPU‑specific | One core for now, designed for cross‑core reuse as CFU playground |

---

# References

\footnotesize

::: {#refs}
:::

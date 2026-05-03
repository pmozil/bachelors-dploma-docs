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
  - \usetikzlibrary{positioning,arrows.meta,shapes.geometric}
  - \usepackage{booktabs}
  - \setbeamertemplate{frame footer}{\insertshortauthor\ — CXU Playground}
---

# This Work's Goals

\begin{columns}[T]
\begin{column}{0.32\textwidth}
\begin{block}{CFU — exists}
Reusable across cores\\[0.4em]
{\footnotesize \textbf{But:} one extension per thread, assembly-only, no shared state}
\end{block}
\end{column}
\begin{column}{0.32\textwidth}
\begin{alertblock}{CXU — spec only}
Multiple extensions, shared state, C-level ABI\\[0.4em]
{\footnotesize \textbf{Gap:} no hardware, no sandbox}
\end{alertblock}
\end{column}
\begin{column}{0.32\textwidth}
\begin{exampleblock}{CXU Playground — this work}
{\footnotesize Hardware implementation + full open-source sandbox running real Linux}
\end{exampleblock}
\end{column}
\end{columns}

---

# System stack

\begin{center}
\begin{tikzpicture}[
  layer/.style={draw, rectangle, minimum width=9cm, minimum height=0.65cm,
                align=center, font=\small},
  hw/.style={layer, fill=blue!20, font=\small\bfseries},
  fw/.style={layer, fill=orange!20},
  os/.style={layer, fill=teal!20},
  lib/.style={layer, fill=green!15},
  app/.style={layer, fill=gray!12},
  node distance=0.12cm
]
  \node[app] (app) {User-space benchmarks \ \ AES, GZIP, TFLite Micro};
  \node[lib,  below=of app]  (lib) {CXU runtime library \ \ header-only C API, \texttt{cxidx} multiplexing, no inline assembly};
  \node[os,   below=of lib]  (os)  {Linux (Buildroot) \ \ OpenSBI → U-Boot → kernel, MMU, perf profiling};
  \node[fw,   below=of os]   (fw)  {LiteX SoC \ \ auto-generated, Wishbone bus, UART / Ethernet / DDR3};
  \node[hw,   below=of fw]   (hw)  {VexiiRiscv + CXU Plugin \ \ SpinalHDL, execute-stage accelerator, \texttt{cxidx}/\texttt{cxdata} CSRs};
\end{tikzpicture}
\end{center}

\vspace{0.3em}
\footnotesize \textbf{Hardware:} Digilent Arty S7-50, Spartan-7 XC7S50, 50 MHz, 256 MB DDR3

---

# CXU plugin in the VexiiRiscv pipeline

\begin{center}
\begin{tikzpicture}[
  node distance=0.55cm and 0.35cm,
  stage/.style={draw, rectangle, minimum width=1.6cm, minimum height=0.9cm,
                fill=blue!12, rounded corners, font=\small\bfseries},
  ex/.style={stage, fill=teal!25},
  cxu/.style={draw, rectangle, minimum width=3cm, minimum height=1.05cm,
              fill=green!15, rounded corners, font=\small\bfseries, align=center},
  arr/.style={-Latex, thick},
  sig/.style={-Latex, dashed, thick, red!60!black}
]
  \node[stage] (f)  {Fetch};
  \node[stage, right=of f]  (d)  {Decode};
  \node[ex,    right=of d]  (e)  {Execute};
  \node[stage, right=of e]  (m)  {Memory};
  \node[stage, right=of m]  (w)  {Writeback};
  \node[cxu, below=1.1cm of e] (cxu) {CXU Plugin\\{\footnotesize Custom Accelerator}};

  \draw[arr] (f)--(d); \draw[arr] (d)--(e); \draw[arr] (e)--(m); \draw[arr] (m)--(w);

  \draw[arr] (d.south) -- ++(0,-0.18) -|
    node[pos=0.78,left,font=\scriptsize]{opcode map} ([xshift=-0.7cm]cxu.north);
  \draw[arr] ([xshift=-0.2cm]e.south) --
    node[right,font=\scriptsize]{\texttt{rs1,rs2}} ([xshift=-0.2cm]cxu.north);
  \draw[arr] ([xshift=0.2cm]cxu.north) --
    node[right,font=\scriptsize]{\texttt{rd}} ([xshift=0.2cm]e.south);
  \draw[sig] (cxu.east) -| node[pos=0.7,right,font=\scriptsize,text=black]{stall} (m.south);
\end{tikzpicture}
\end{center}

\begin{columns}[T]
\begin{column}{0.48\textwidth}
\textbf{What the plugin does}
\begin{itemize}
  \item Intercepts custom-0/1/2/3 opcodes at Decode
  \item Forwards \texttt{rs1}/\texttt{rs2} directly from register file
  \item Stalls pipeline for multi-cycle operations
  \item \texttt{cxidx} CSR selects the active extension
\end{itemize}
\end{column}
\begin{column}{0.48\textwidth}
\textbf{Why it matters}
\begin{itemize}
  \item Zero-copy operand path — no DMA, no bus transaction
  \item Single-cycle or stalled — no polling loop in software
  \item Multiple extensions share the same hardware slot
  \item C callable — runtime library hides the CSR writes
\end{itemize}
\end{column}
\end{columns}

---

# The Playground environment

\begin{columns}[T]
\begin{column}{0.32\textwidth}
\textbf{SoC generation}\\[0.3em]
One Python script builds the entire SoC:
\begin{itemize}
  \item VexiiRiscv with CXU plugin wired in
  \item Memory map, interrupt controller, DTS auto-generated
  \item Bitstream → FPGA in a single \texttt{make} call
\end{itemize}
\end{column}
\begin{column}{0.32\textwidth}
\textbf{Linux environment}\\[0.3em]
Buildroot cross-compiles:
\begin{itemize}
  \item Linux kernel + root filesystem
  \item OpenSBI → U-Boot boot chain
  \item \texttt{perf} + \texttt{minstret} for cycle-accurate profiling
  \item CXU accessible from ordinary user-space C
\end{itemize}
\end{column}
\begin{column}{0.32\textwidth}
\textbf{Runtime library}\\[0.3em]
Header-only C API:
\begin{itemize}
  \item No inline assembly in application code
  \item Manages \texttt{cxidx} register transparently
  \item Paired software reference for every extension
\end{itemize}
\end{column}
\end{columns}

\vspace{0.5em}
\begin{block}{Developer workflow}
Edit SpinalHDL extension -> rebuild SoC -> boot Linux -> run benchmark -> all in one repo: \url{https://github.com/pmozil/CXU-playground}
\end{block}

---

# Three extensions — one framework

\begin{columns}[T]
\begin{column}{0.32\textwidth}
\textbf{AES GF($2^8$) accelerator}\\[0.2em]
{\footnotesize Single-cycle finite-field instruction replaces a 5-instruction inner loop per byte}\\[0.5em]
\begin{center}
{\Large\bfseries 5.25×} speedup\\
{\footnotesize stable, 128 B – 16 KB}
\end{center}
\vspace{0.3em}
{\footnotesize 209 logic cells, consistent with Marshall et al. (4× RV32, 10× RV64)}
\end{column}
\begin{column}{0.32\textwidth}
\textbf{GZIP / DEFLATE}\\[0.2em]
{\footnotesize 4 combinational instructions: \texttt{bitrev}, \texttt{mask}, \texttt{huft\_idx}, \texttt{copy\_addr}}\\[0.5em]
\begin{center}
{\Large\bfseries $\sim$10\%} CPU time\\
{\footnotesize end-to-end reduction}
\end{center}
\vspace{0.3em}
{\footnotesize 20 cells, LZ77 search \& filesystem I/O dilute gains; accelerated primitives: 12–15\% of inner loop}
\end{column}
\begin{column}{0.32\textwidth}
\textbf{TFLite Micro MAC}\\[0.2em]
{\footnotesize Fused multiply-accumulate for INT8 quantised inference}\\[0.5em]
\begin{center}
{\Large\bfseries $\sim$13\%} latency\\
{\footnotesize 1577 ms → 1396 ms}
\end{center}
\vspace{0.3em}
{\footnotesize Folded into pipeline (no top-level instance), confirms memory-bound ceiling without RAM access}
\end{column}
\end{columns}

\vspace{0.4em}
\begin{exampleblock}{}
Even a handful of tightly coupled instructions yields substantial gains for arithmetic-intensive workloads on commodity FPGA hardware running real Linux.
\end{exampleblock}

---

# Limitations \& future work

\begin{columns}[T]
\begin{column}{0.48\textwidth}
\textbf{Current limitations}
\begin{itemize}
  \item \textbf{CSR latency:} \texttt{cxidx}/\texttt{cxdata} traverse the Wishbone bus — full transaction per state access. Design for one-time configuration.
  \item \textbf{No context-switch support:} CXU state not saved/restored on preemption — safe for single-process only.
  \item \textbf{No Device Tree entries:} extension addresses are hard-coded in the runtime library.
\end{itemize}
\end{column}
\begin{column}{0.48\textwidth}
\textbf{Future directions}
\begin{itemize}
  \item Kernel driver: \texttt{cxidx}/\texttt{cxdata} save/restore in task struct → multi-process safety
  \item Native pipeline CSRs (bypass Wishbone) → zero-cycle state access
  \item LiteX DTS emission for capability discovery
  \item Post-quantum crypto: NTT butterfly / modular reduction — literature shows up to 9.6× for Kyber
\end{itemize}
\end{column}
\end{columns}

---

# Summary

\begin{block}{What was built}
\begin{itemize}
  \item \textbf{First CXU hardware implementation} — SpinalHDL plugin for VexiiRiscv: opcode interception, pipeline stall, CSR support
  \item \textbf{CXU Playground} — open-source, full-stack sandbox: LiteX SoC + Buildroot Linux + C runtime library
  \item \textbf{Three validated extensions} — AES GF($2^8$), GZIP DEFLATE, TFLite Micro MAC
\end{itemize}
\end{block}

\begin{exampleblock}{Key takeaway}
A composable custom extension interface previously existing only as a design document now runs on real hardware under Linux — and the playground makes it reproducible.
\end{exampleblock}

\vspace{0.5em}
\centering\footnotesize\url{https://github.com/pmozil/CXU-playground}

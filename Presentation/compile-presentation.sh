#!/usr/bin/env sh
set -e

pandoc presentation.md \
  -t beamer \
  --pdf-engine=xelatex \
  --citeproc \
  --bibliography=bibliography.bib \
  -o presentation.pdf

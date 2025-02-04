#!/bin/bash

# Define directories
input_dir="/mnt/c/Users/hardijm1/Projects/jICA/full_maps/16_comp"
output_tex="full_components_16.tex"

# Start LaTeX document
echo "\documentclass{article}" > $output_tex
echo "\usepackage{graphicx}" >> $output_tex
echo "\usepackage{caption}" >> $output_tex
echo "\usepackage{subcaption}" >> $output_tex
echo "\begin{document}" >> $output_tex
echo "\title{Full Cohort Components}" >> $output_tex
echo "\author{Neurdy Lab}" >> $output_tex
echo "\maketitle" >> $output_tex
echo "\section*{Full Cohort Components}" >> $output_tex

# Loop through components
for i in {1..80}
do
    # Add LaTeX for each component
    echo "\subsection*{Component ${i}}" >> $output_tex
    echo "\begin{figure}[h]" >> $output_tex
    echo "    \centering" >> $output_tex

    echo "    \begin{subfigure}[b]{0.45\textwidth}" >> $output_tex
    echo "        \centering" >> $output_tex
    echo "        \includegraphics[width=\textwidth]{${input_dir}/full_eeg_${i}.png}" >> $output_tex
    echo "        \caption{EEG Image}" >> $output_tex
    echo "    \end{subfigure}" >> $output_tex

    echo "    \hfill" >> $output_tex

    echo "    \begin{subfigure}[b]{0.45\textwidth}" >> $output_tex
    echo "        \centering" >> $output_tex
    echo "        \includegraphics[width=\textwidth]{${input_dir}/full_${i}.axi.png}" >> $output_tex
    echo "        \caption{Axial Montage}" >> $output_tex
    echo "    \end{subfigure}" >> $output_tex

    echo "    \hfill" >> $output_tex

    echo "    \begin{subfigure}[b]{0.45\textwidth}" >> $output_tex
    echo "        \centering" >> $output_tex
    echo "        \includegraphics[width=\textwidth]{${input_dir}/full_${i}.sag.png}" >> $output_tex
    echo "        \caption{Sagittal Montage}" >> $output_tex
    echo "    \end{subfigure}" >> $output_tex

    echo "    \caption{Component ${i}}" >> $output_tex
    echo "\end{figure}" >> $output_tex
    echo "\clearpage" >> $output_tex
done

# End LaTeX document
echo "\end{document}" >> $output_tex

# Compile the LaTeX document
pdflatex $output_tex

# Notify user of completion
echo "LaTeX document compiled successfully!"

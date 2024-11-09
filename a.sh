#!/bin/bash


output_dir="sol_files"


mkdir -p "$output_dir"

# Find all .sol files and recreate directory structure in the output directory
find . -type f -name "*.sol" | while read file; do

    mkdir -p "$output_dir/$(dirname "$file")"
    # Copy the .sol file to the new directory structure
    cp "$file" "$output_dir/$file"
done

echo "All .sol files have been copied to the '$output_dir' directory."

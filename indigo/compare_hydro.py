#!/usr/bin/env python
# Compare patches with Hydro.
# Most patches should be valid for both distributions.

import os
import glob

# Distribution directory: Indigo
distro_dir = os.path.dirname(os.path.realpath(__file__))

# Hydro directory
hydro_dir = os.path.join(distro_dir, '..', 'hydro')

def process_paths(patches):
  processed_paths = list()
  for patch in patches:
    processed_paths.append(os.path.join(patch.split(os.sep)[-2],
                                        os.path.basename(patch)))
  return processed_paths

# For each Indigo package
for package in os.listdir(distro_dir):
  # If it also exists in Hydro
  if package in os.listdir(hydro_dir):
    # Search for patch in Hydro and Indigo
    distro_patches = glob.glob(os.path.join(distro_dir, package, '*.patch'))
    hydro_patches = glob.glob(os.path.join(hydro_dir, package, '*.patch'))
    distro_patches = process_paths(distro_patches)
    hydro_patches = process_paths(hydro_patches)
    for patch in hydro_patches:
      if not patch in distro_patches:
        print(patch)

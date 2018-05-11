#!/bin/bash

function download {
  echo "Download sami.phar"

  curl -O http://get.sensiolabs.org/sami.phar
}

function createConfig {
  # Ask user for necessary information about the configuration file.
  echo "Title of the documentation:"
  read title
  echo "Full path to the project directory (e.g. /var/www/html/project):"
  read projectDir
  echo "Directory which should documented (e.g. lib):"
  read docDir
  echo "Output directory name (e.g. doc):"
  read outDir
  echo "Exclude directories (e.g. test resources):"
  read -a excludeDirs

  cacheDir="${projectDir}/samiCache"

  # Write file.
  echo "<?php" > sami-config.php
  echo "" >> sami-config.php
  echo "use Sami\Sami;" >> sami-config.php
  echo "use Symfony\Component\Finder\Finder;" >> sami-config.php
  echo "" >> sami-config.php
  echo "\$iterator = Finder::create()" >> sami-config.php
  echo "    ->files()" >> sami-config.php
  echo "    ->name( '*.php' )" >> sami-config.php

  for exclude in ${excludeDirs[@]}; do
    echo "    ->exclude( '${exclude}' )" >> sami-config.php
  done

  echo "    ->in( '${projectDir}/${docDir}' );" >> sami-config.php
  echo "" >> sami-config.php
  echo "\$options = [" >> sami-config.php
  echo "    'title' => '${title}'," >> sami-config.php
  echo "    'build_dir' => '${projectDir}/${outDir}'," >> sami-config.php
  echo "    'cache_dir' => '${projectDir}/samiCache'," >> sami-config.php
  echo "    'default_opened_level' => 2," >> sami-config.php
  echo "];" >> sami-config.php
  echo "" >> sami-config.php
  echo "return new Sami( \$iterator, \$options );" >> sami-config.php
  # File finished.
}

cacheDir=""
currentDir=$(pwd)
phar="${currentDir}/sami.phar"
config="${currentDir}/sami-config.php"

# Download sami.phar if not exists.
if [ ! -e ${phar} ]; then
  download
fi

# Create configuration file.
createConfig

# Run sami.phar
(php sami.phar update ${config})

# Remove the cache directory.
if [ -e ${cacheDir} ]; then
  echo ""
  echo "Removing cache directory \"${cacheDir}\""
  (rm -rf ${cacheDir})
  echo "Cache directory removed"
fi

# Script ends here.
echo ""
echo "Your documentation was successfully created."
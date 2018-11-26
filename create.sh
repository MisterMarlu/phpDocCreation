#!/bin/bash

# Decode an JSON array or object.
function jsonDecode() {
  json=$1
  key=$2

  echo ${json} | jq -r ${key}
}

# Downloads the PHP Archive "sami.phar".
function download {
  echo "Download sami.phar"

  curl -O http://get.sensiolabs.org/sami.phar
}

# Creates the configuration file for sami.phar.
function createConfig {
  versions=()
  github=false
  ghUser=""
  ghRepo=""

  # Ask user for necessary information about the configuration file.
  read -p "Title of the documentation: " title
  read -p "Full path to the project directory (e.g. /var/www/html/project): " projectDir
  read -p "Directory which should documented (e.g. lib): " docDir
  read -p "Output directory name (e.g. doc): " outDir
  echo "Exclude directories (e.g. test resources):"
  read -a excludeDirs

  while true; do
    read -p "Include github repository? " tmp
    case ${tmp} in
      [Yy]* ) github=true; break;;
      [Nn]* ) break;;
      * ) echo "Please answer with yes or no";;
    esac
  done

  if ${github}; then
    while true; do
      read -p "Github username: " ghUser
      [[ ! -z ${ghUser} ]] && break;
    done

    while true; do
      read -p "Github repository name: " ghRepo
      [[ ! -z ${ghRepo} ]] && break;
    done

    json=$(curl "https://api.github.com/repos/${ghUser}/${ghRepo}/tags")
    versions=$(echo "${json}" | jq -c ".[]")
  fi

  cacheDir="${projectDir}/samiCache"

  # Write the file.
  echo "<?php" > ${config}
  echo "" >> ${config}
  echo "use Sami\Sami;" >> ${config}
  echo "use Symfony\Component\Finder\Finder;" >> ${config}

  if ${github}; then
    echo "use Sami\RemoteRepository\GitHubRemoteRepository;" >> ${config}
    echo "use Sami\Version\GitVersionCollection;" >> ${config}
  fi

  echo "" >> ${config}
  echo "\$dir = '${projectDir}';" >> ${config}
  echo "" >> ${config}

  if ${github}; then
    echo "\$versions = GitVersionCollection::create( \$dir )" >> ${config}

    for version in ${versions[@]}; do
      versionNumber=$(jsonDecode ${version} ".name")
      echo "    ->add( '${versionNumber}', '${versionNumber}' )" >> ${config}
    done

    echo "    ->add( 'master', 'master' );" >> ${config}
    echo "" >> ${config}
  fi

  echo "\$iterator = Finder::create()" >> ${config}
  echo "    ->files()" >> ${config}
  echo "    ->name( '*.php' )" >> ${config}

  for exclude in ${excludeDirs[@]}; do
    echo "    ->exclude( '${exclude}' )" >> ${config}
  done

  echo "    ->in( \$dir . '/${docDir}' );" >> ${config}
  echo "" >> ${config}
  echo "\$options = [" >> ${config}
  echo "    'title' => '${title}'," >> ${config}

  if ${github}; then
    echo "    'build_dir' => \$dir . '/${outDir}/%version%'," >> ${config}
    echo "    'cache_dir' => \$dir . '/samiCache/%version%'," >> ${config}
  else
    echo "    'build_dir' => \$dir . '/${outDir}'," >> ${config}
    echo "    'cache_dir' => \$dir . '/samiCache'," >> ${config}
  fi

  echo "    'default_opened_level' => 2," >> ${config}

  if ${github}; then
    echo "    'versions' => \$versions," >> ${config}
    echo "    'remote_repository' => new GitHubRemoteRepository( '${ghUser}/${ghRepo}', \$dir )," >> ${config}
  fi

  echo "];" >> ${config}
  echo "" >> ${config}
  echo "return new Sami( \$iterator, \$options );" >> ${config}
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

# Remove sami.phar.
if [ -e ${phar} ]; then
  echo ""
  echo "Removing sami.phar \"${phar}\""
  (rm -rf ${phar})

  if [ -e ${config} ]; then
    (rm -f ${config})
  fi

  echo "Sami.phar removed"
fi

# Script ends here.
echo ""
echo "Your documentation was successfully created."
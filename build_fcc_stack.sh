#!/bin/sh
function build {
    cd ${1}
    mkdir build;cd build
    out="$(cmake -DCMAKE_INSTALL_PREFIX=../install ..)"
    rc=$?
    if [[ $rc != 0 ]]; then
      echo "${out}"
      exit $rc
    fi
    out="$(make -j4 install)"
    rc=$?
    if [[ $rc != 0 ]]; then
      echo "${out}"
      exit $rc
    fi
    cd ../../
    echo "- ${1} done"
}

function clone {
  git clone https://github.com/$user/${1}.git
  cd ${1}
  git checkout -b ${2}_b ${2}
  cd ..
}


if [[ $# -le 2 ]]; then
  echo "Usage: ./build_fcc_stack.sh workdirectory installdirectory [user]"
  exit 1
fi

workdir=${1}
installdir=${2}

if [[ $# -ge 3 ]]; then
  user=${3}
else
  user="HEP-FCC"
fi

mkdir -p $workdir
cd $workdir

######################################################################
echo "Get all repos"
######################################################################
if [[ -z "$FILESYSTEM" ]]; then
  # only check this out if we are not testing the central installations (for jenkins)
  clone "podio" $podio_version
  clone "fcc-edm" $edm_version
  clone "fcc-physics" $physics_version
fi

clone "heppy" $heppy_version
# only on lxplus & co
if [[ `dnsdomainname` = 'cern.ch' ]] ; then
  clone "FCCSW" $release_version
fi


######################################################################
echo "Setup environment"
######################################################################
if [[ -z "$FILESYSTEM" ]]; then
  # make sure we take the local installs of podio and fcc-edm
  export PODIO=$installdir
  export FCCEDM=$installdir
  export FCCPHYSICS=$installdir
fi

source ../init_fcc_stack.sh $FILESYSTEM
cd heppy
source ./init.sh
cd ..

######################################################################
echo "Build all repos"
######################################################################
if [[ -z "$FILESYSTEM" ]]; then
  build "podio"
  build "fcc-edm"
  build "fcc-physics"
fi
if [[ `dnsdomainname` = 'cern.ch' ]] ; then
  cd FCCSW
  out="$(make -j12)"
  rc=$?
  if [[ $rc != 0 ]]; then
    echo "${out}"
    exit $rc
  fi
  echo "- FCCSW done"
  cd ..
fi

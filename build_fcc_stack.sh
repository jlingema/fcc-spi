#!/bin/sh
function build {
    cd ${1}
    mkdir build;cd build
    out="$(cmake -DCMAKE_INSTALL_PREFIX=${2} -DCMAKE_BUILD_TYPE=$BUILDTYPE ..)"
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
  rm -rf ${1}
  git clone https://github.com/HEP-FCC/${1}.git
  cd ${1}
  git checkout -b ${2}_b ${3}
  cd ..
}

# If no installation directory is specified via command line, assume we are building a release
# For this the FILESYSTEM environment variable needs to be set.
if [[ $# != 1 ]]; then
  if [[ "$FILESYSTEM" = "afs" ]]; then
      SWBASE=/afs/cern.ch/exp/fcc/sw
      RELEASEBASE=$SWBASE
  elif [[ "$FILESYSTEM" = "cvmfs" ]]; then
      SWBASE=$cvmfs_out
      RELEASEBASE=/cvmfs/fcc.cern.ch/sw
  fi
else
  SWBASE=${1}
  RELEASEBASE=$SWBASE
  islocal=1
fi

# If not directory is specified and FILESYSTEM is not set, abort:
if [[ -z "$SWBASE" ]]; then
  echo "either set FILESYSTEM or provide installdirectory!"
  echo "Usage: ./build_fcc_stack.sh installdir"
  exit 1
fi

# If no external_prefix is specified, assume we'll find it in the release directory (true for releases)
if [[ -z "$externals_prefix" ]]; then
  export externals_prefix=$RELEASEBASE/$externals_version
fi

# collect name of the setup script:
setupfile=$SWBASE/$release_name/setup.sh
if [[ "$BUILDTYPE" = "Debug" ]]; then
  setupfile=$SWBASE/$release_name/setup_debug.sh
fi
if [[ ! -d $SWBASE/$release_name ]]; then
  mkdir -p $SWBASE/$release_name
fi
# make sure we start from scratch
rm -f $setupfile
touch $setupfile

if [[ "$release_name" = "snapshot" ]]; then
  # take master versions for snapshot
  podio_rel="master"
  edm_rel="master"
  physics_rel="master"
  fccsw_rel="master"
  fccsw_version="snapshot"
  export podio_version="snapshot"
  export edm_version="snapshot"
  export physics_version="snapshot"
else
  # for releases in jenkins, we specify the versions, assume tags have name "v"+str(version)
  podio_rel=v$podio_version
  edm_rel=v$edm_version
  physics_rel=v$physics_version
  fccsw_rel=v$release_name
fi

# Now create the setup script by saving all the environment variables
echo "export podio_version=$podio_version" >> $setupfile
echo "export edm_version=$edm_version" >> $setupfile
echo "export physics_version=$physics_version" >> $setupfile
echo "export dag_version=$dag_version" >> $setupfile
echo "export externals_prefix=$externals_prefix" >> $setupfile
echo "export release_name=$release_name" >> $setupfile
echo "export BUILDTYPE=$BUILDTYPE" >> $setupfile
echo "export FCCSWPATH=$RELEASEBASE/$release_name" >> $setupfile
echo "source $RELEASEBASE/init_fcc_stack.sh $FILESYSTEM $lcg_version" >> $setupfile
if [[ islocal = 1 && ! -z "$externals_prefix" ]]; then
  echo "add_to_path CMAKE_PREFIX_PATH $externals_prefix" >> $setupfile
fi

# needed to pick up the local installation for cvmfs in the init script below
if [[ "$FILESYSTEM" = "cvmfs" || $islocal == 1 ]]; then
  curl https://raw.githubusercontent.com/HEP-SF/tools/master/hsf_get_platform.py > hsf_get_platform.py
  if [[ "$BUILDTYPE" = "Debug" ]]; then
    build=dbg
  elif [[ "$BUILDTYPE" = "Release" ]]; then
    build=opt
  fi

  BINARY_TAG=`python hsf_get_platform.py --buildtype=$build --compiler=gcc49`
  export PODIO=$SWBASE/$release_name/podio/$podio_version/$BINARY_TAG
  export FCCEDM=$SWBASE/$release_name/fcc-edm/$edm_version/$BINARY_TAG
  export FCCPHYSICS=$SWBASE/$release_name/fcc-physics/$physics_version/$BINARY_TAG
  export FCCDAG=$SWBASE/$release_name/dag/$physics_version/$BINARY_TAG
fi

# update the init script
cp ./init_fcc_stack.sh $SWBASE/.
source $SWBASE/init_fcc_stack.sh $FILESYSTEM $lcg_version

# Compile and install all the repositories
# PODIO
clone podio $podio_version $podio_rel
echo Installing podio to $PODIO
build podio $PODIO

# FCC-EDM
clone fcc-edm $edm_version $edm_rel
echo Installing fcc-edm to $FCCEDM
build fcc-edm $FCCEDM

# FCC-physics
clone fcc-physics $physics_version $physics_rel
echo Installing fcc-physics to $FCCPHYSICS
build fcc-physics $FCCPHYSICS

# DAG
clone dag $dag_version $dag_rel
echo Installing fcc-dag to $FCCDAG
build dag $FCCDAG

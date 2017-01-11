#!/bin/sh -u
# This script sets up the commonly used software for FCC software projects:
# - Linux machines at CERN:
#    The software is taken from cvmfs or afs depending on command (source init_fcc_stack.sh cvmfs/afs).
# - MacOS / Linux elsewhere: We assume the software is installed locally and their environment is set.

# Add the passed value only to path if it's not already in there.
function add_to_path {
    if [ -z "$1" ] || [[ "$1" == "/lib" ]]; then
        return
    fi
    path_name=${1}
    eval path_value=\$$path_name
    path_prefix=${2}
    case ":$path_value:" in
      *":$path_prefix:"*) :;;        # already there
      *) path_value=${path_prefix}:${path_value};; # or prepend path
    esac
    eval export ${path_name}=${path_value}
}

platform='unknown'
unamestr=`uname`

if [[ "$unamestr" == 'Linux' ]]; then
    fs=$1
    if [ -z "$fs" ] || [[ ! -d "/$fs" ]]; then
        fs="afs"
        echo "INFO - Defaulting to afs as file system."
    fi
    if [[ $fs = 'afs' ]]; then
        export LCGPREFIX=/afs/cern.ch/sw/lcg
        export FCCSWPATH=/afs/cern.ch/exp/fcc/sw/0.8
        export LHCBPATH=/afs/cern.ch/lhcb/software/releases
    else
        export LCGPREFIX=/cvmfs/sft.cern.ch/lcg
        export FCCSWPATH=/cvmfs/fcc.cern.ch/sw/0.8
        export LHCBPATH=/cvmfs/lhcb.cern.ch/lib
    fi
    platform='Linux'
    echo "Platform detected: $platform"
    if [[ -d "$LCGPREFIX" ]] ; then
        podio_version=0.5
        fccedm_version=0.5
        fccphysics_version=0.2
        delphes_version=3.4.1pre01
        pythia_version=219
        lcg_version=LCG_87
        gaudi_version=v28r1
        export PLATFORM=x86_64-slc6-gcc49
        # Check if build type is set, if not default to release build
        if [ -z "$BUILDTYPE" ] || [[ "$BUILDTYPE" == "Release" ]]; then
            export BINARY_TAG=$PLATFORM-opt
            export CMAKE_BUILD_TYPE="Release"
        else
            export BINARY_TAG=$PLATFORM-dbg
            export CMAKE_BUILD_TYPE="Debug"
        fi
        export LCGPATH=$LCGPREFIX/views/$lcg_version/$BINARY_TAG
        # The LbLogin sets VERBOSE to 1 which increases the compilation output. If you want details set this to 1 by hand.
        unset VERBOSE
        # Only source the lcg setup script if paths are not already set
        # (necessary because of incompatible python install in view)
        case ":$LD_LIBRARY_PATH:" in
            *":$LCGPATH/lib64:"*) :;;       # Path is present do nothing
            *) source $LCGPATH/setup.sh;;   # otherwise setup
        esac
        # This path is used below to select software versions

        echo "Software taken from $FCCSWPATH and $lcg_version"
        # If podio or EDM not set locally already, take them from afs
        if [ -z "$PODIO" ]; then
            export PODIO=$FCCSWPATH/podio/$podio_version/$BINARY_TAG
        else
            echo "Take podio: $PODIO"
        fi
        if [ -z "$FCCEDM" ]; then
            export FCCEDM=$FCCSWPATH/fcc-edm/$fccedm_version/$BINARY_TAG
        else
            echo "Take fcc-edm: $FCCEDM"
        fi
        if [ -z "$FCCPHYSICS" ]; then
            export FCCPHYSICS=$FCCSWPATH/fcc-physics/$fccphysics_version/$BINARY_TAG
        fi
        export DELPHES_DIR=$FCCSWPATH/delphes/$delphes_version/$BINARY_TAG
        export PYTHIA8_XML=$LCGPATH/share/Pythia8/xmldoc
        export PYTHIA8DATA=$PYTHIA8_XML
        export HEPMC_PREFIX=$LCGPATH

        # add DD4hep
        export inithere=$PWD
        cd $LCGPATH
        source bin/thisdd4hep.sh
        cd $inithere
        # temporary because of LCG & DD4hep mismatch of setting up cmake configs
        add_to_path CMAKE_PREFIX_PATH $LCGPREFIX/releases/$lcg_version/DD4hep/00-17/$BINARY_TAG
        # temporary because no LHCb installation yet:
        # export Gaudi_DIR=$FCCSWPATH/gaudi/$gaudi_version/$BINARY_TAG
        # export GaudiProject_DIR=$FCCSWPATH/gaudi/$gaudi_version/$BINARY_TAG
        export CMTPROJECTPATH=$LCGPREFIX/releases/$lcg_version/
        add_to_path CMAKE_PREFIX_PATH $LHCBPATH/GAUDI/GAUDI_$gaudi_version/InstallArea/$BINARY_TAG
        # add Geant4 data files
        if [[ $fs = 'afs' ]]; then
            source /afs/cern.ch/sw/lcg/external/geant4/10.2/setup_g4datasets.sh
        else
            source /cvmfs/geant4.cern.ch/geant4/10.2/setup_g4datasets.sh
        fi
    else
        # cannot find afs / cvmfs: so get rid of this to avoid confusion
        unset FCCSWPATH
    fi
    add_to_path LD_LIBRARY_PATH $FCCEDM/lib
    add_to_path LD_LIBRARY_PATH $PODIO/lib
    add_to_path LD_LIBRARY_PATH $PYTHIA8_DIR/lib
    add_to_path LD_LIBRARY_PATH $FCCPHYSICS/lib
elif [[ "$unamestr" == 'Darwin' ]]; then
    platform='Darwin'
    echo "Platform detected: $platform"
    add_to_path DYLD_LIBRARY_PATH $FCCEDM/lib
    add_to_path DYLD_LIBRARY_PATH $PODIO/lib
    add_to_path DYLD_LIBRARY_PATH $PYTHIA8_DIR/lib
    add_to_path DYLD_LIBRARY_PATH $FCCPHYSICS/lib
fi

# let ROOT know where the fcc-edm and -physics headers live.
add_to_path ROOT_INCLUDE_PATH $PODIO/include
add_to_path ROOT_INCLUDE_PATH $FCCEDM/include/datamodel
add_to_path ROOT_INCLUDE_PATH $FCCPHYSICS/include

add_to_path PYTHONPATH $PODIO/python

add_to_path PATH $FCCPHYSICS/bin

add_to_path CMAKE_PREFIX_PATH $FCCEDM
add_to_path CMAKE_PREFIX_PATH $PODIO
add_to_path CMAKE_PREFIX_PATH $PYTHIA8_DIR
if [ "$DELPHES_DIR" ]; then
    add_to_path CMAKE_PREFIX_PATH $DELPHES_DIR
fi

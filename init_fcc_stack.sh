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
    LCGPREFIX=/cvmfs/sft.cern.ch/lcg
    export FCCSWPATH=/cvmfs/fcc.cern.ch/sw/0.8
    platform='Linux'
    echo "Platform detected: $platform"
    if [[ -d "$LCGPREFIX" ]] ; then
        platform_tag=$1
        if [ -z "$platform_tag" ] ; then
            platform_tag=x86_64-slc6-gcc49
        fi
        # Check if build type is set, if not default to release build
        if [ -z "$BUILDTYPE" ] || [[ "$BUILDTYPE" == "Release" ]]; then
            export BINARY_TAG=${platform_tag}-opt
            export CMAKE_BUILD_TYPE="Release"
        else
            export BINARY_TAG=${platform_tag}-dbg
            export CMAKE_BUILD_TYPE="Debug"
        fi
        # Set up Gaudi + Dependencies
        export lcg_version=LCG_88
        export LCGPATH=$LCGPREFIX/views/${lcg_version}/$BINARY_TAG
        # Only source the lcg setup script if paths are not already set
        # (necessary because if incompatible pythia install in view)
        case ":$LD_LIBRARY_PATH:" in
            *":$LCGPATH/lib64:"*) :;;       # Path is present do nothing
            *) source $LCGPATH/setup.sh;;   # otherwise setup
        esac

        echo "Software taken from $FCCSWPATH and $LCGPATH"
        # If podio or EDM not set locally already, take them from afs
        if [ -z "$PODIO" ]; then
            export PODIO=$FCCSWPATH/podio/0.6/$BINARY_TAG
        else
            echo "Take podio: $PODIO"
        fi
        if [ -z "$FCCEDM" ]; then
            export FCCEDM=$FCCSWPATH/fcc-edm/0.5/$BINARY_TAG
        else
            echo "Take fcc-edm: $FCCEDM"
        fi
        if [ -z "$FCCPHYSICS" ]; then
            export FCCPHYSICS=$FCCSWPATH/fcc-physics/0.2/$BINARY_TAG
        fi
        export FCCDAG=$FCCSWPATH/dag/0.1/$BINARY_TAG
        export DELPHES_DIR=$FCCSWPATH/delphes/3.4.1pre02/$BINARY_TAG
        export PYTHIA8_DIR=$LCGPATH
        export PYTHIA8_XML=$LCGPATH/share/Pythia8/xmldoc
        export PYTHIA8DATA=$PYTHIA8_XML
        export HEPMC_PREFIX=$LCGPATH

        # add DD4hep (workaround for missing DD4hepConfig in standard locations)
        # this also currently sets up the ROOT environment (sources thisroot.sh)
        export inithere=$PWD
        cd $LCGPREFIX/releases/${lcg_version}/DD4hep/00-20/$BINARY_TAG
        source bin/thisdd4hep.sh
        cd $inithere

        # add gaudi to cmake path:
        # in case we want to use lhcb installation when ready:
        # LHCBPATH=/cvmfs/lhcb.cern.ch/lib/lhcb
        # add_to_path CMAKE_PREFIX_PATH $LHCBPATH/GAUDI/GAUDI_v28r1/$BINARY_TAG
        add_to_path CMAKE_PREFIX_PATH $FCCSWPATH/gaudi/$BINARY_TAG
        # add Geant4 data files
        source /cvmfs/geant4.cern.ch/geant4/10.2/setup_g4datasets.sh
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

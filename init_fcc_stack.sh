#!/bin/sh -u
# This script sets up the commonly used software for FCC software projects:
# - Linux machines at CERN:
#    The software is taken from cvmfs
# - MacOS / Linux elsewhere: We assume the software is installed locally and their environment is set.

function add_to_path {
    # Add the passed value only to path if it's not already in there.
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

function check_local_setup() {
    # checks only if environment variables are non-empty and prints messages
    if [ -z "$PODIO" ]; then
        echo "[ERROR] No podio installation set up, please set PODIO to the installation directory"
    fi
    if [ -z "$FCCEDM" ]; then
        echo "[ERROR] No fcc-edm installation set up, please set FCCEDM to the installation directory"
    fi
    if [ -z "$PYTHIA8_DIR" ]; then
        echo "[ERROR] No Pythia8 installation set up, please set PYTHIA8_DIR to the installation directory"
    fi
    if [ -z "$FCCPHYSICS" ]; then
        echo "[ERROR] No fcc-physics installation set up, please set FCCPHYSICS to the installation directory"
    fi
    if [ -z "$FCCDAG" ]; then
        echo "[ERROR] No DAG installation set up, please set FCCDAG to the installation directory"
    fi
}

function check_support {
    # check if the variable is an existing directory, otherwise assume we do not support it
    if [[ ! -d "$1" ]]; then
        echo "[ERROR] $1 not found in FCC release ${FCCSWPATH}"
        return 1
    fi
}

unamestr=`uname`

if [[ "$unamestr" == 'Linux' ]]; then
    LCGPREFIX=/cvmfs/sft.cern.ch/lcg
    export FCCSWPATH=/cvmfs/fcc.cern.ch/sw/0.8
    if [[ -d "$LCGPREFIX" ]] ; then
        # First construct the full platform
        platform=$1
        os=`python $FCCSWPATH/tools/hsf_get_platform.py --get=os`
        # once we support cc7 this should be used:
        #if [[ $os =~ ^(cc7|slc6)$ ]]; then
        if [[ "$os" = "slc6" ]]; then
            arch=`python $FCCSWPATH/tools/hsf_get_platform.py --get=architecture`
            default_compiler=gcc49
            if [ -z "$platform" ] ; then
                platform=${arch}-${os}-${default_compiler}
            else
                # Check the input
                if [[ ! $platform =~ ^${arch}-${os}-gcc[0-9]+$ ]]; then
                    echo "[WARNING] invalid input, defaulting to ${arch}-${os}-${default_compiler}"
                    platform=${arch}-${os}-${default_compiler}
                fi
            fi
            echo "Platform detected: ${platform}"
            # Check if build type is set, if not default to release build
            if [ -z "$BUILDTYPE" ] || [[ "$BUILDTYPE" == "Release" ]]; then
                export BINARY_TAG=${platform}-opt
                export CMAKE_BUILD_TYPE="ReleaseWithDebInfo"
            else
                export BINARY_TAG=${platform}-dbg
                export CMAKE_BUILD_TYPE="Debug"
            fi
            # clean up tmp vars for platform detection
            unset os; unset arch; unset default_compiler;unset platform
            # Which LCG version do we want to use?
            export lcg_version=LCG_88
            export LCGPATH=$LCGPREFIX/views/${lcg_version}/$BINARY_TAG
            if [[ ! -d "$LCGPATH" ]]; then
                echo "[ERROR] selected platform (${platform}) not supported in LCG release ${lcg_version}."
                return 1
            fi
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
                if ! check_support $PODIO; then unset PODIO; return 1; fi
            else
                echo "Take podio: $PODIO"
            fi
            if [ -z "$FCCEDM" ]; then
                export FCCEDM=$FCCSWPATH/fcc-edm/0.5/$BINARY_TAG
                if ! check_support $FCCEDM; then unset FCCEDM; return 1; fi
            else
                echo "Take fcc-edm: ${FCCEDM}"
            fi
            if [[ -z "$FCCDAG" ]]; then
                export FCCDAG=$FCCSWPATH/dag/0.1/$BINARY_TAG
                if ! check_support $FCCDAG; then unset FCCDAG; return 1; fi
            fi
            if [ -z "$FCCPHYSICS" ]; then
                export FCCPHYSICS=$FCCSWPATH/fcc-physics/0.2/$BINARY_TAG
                if ! check_support $FCCPHYSICS; then unset FCCPHYSICS; return 1; fi
            fi
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
            # if we go that route, we may need to set LCG_SYSTEM and LCG_releases_base in FCCSW CMake
            # LHCBPATH=/cvmfs/lhcb.cern.ch/lib/lhcb
            # add_to_path CMAKE_PREFIX_PATH $LHCBPATH/GAUDI/GAUDI_v28r1/$BINARY_TAG
            add_to_path CMAKE_PREFIX_PATH $FCCSWPATH/gaudi/v28r2/$BINARY_TAG
            # add Geant4 data files
            source /cvmfs/geant4.cern.ch/geant4/10.2/setup_g4datasets.sh
        else
            echo "Platform detected: Linux (centrally unsupported flavor)"
            check_local_setup
        fi
    else
        echo "Platform detected: Linux (without cvmfs)"
        # cannot find afs / cvmfs: so get rid of this to avoid confusion
        unset FCCSWPATH
        check_local_setup
    fi
    add_to_path LD_LIBRARY_PATH $FCCEDM/lib
    add_to_path LD_LIBRARY_PATH $PODIO/lib
    add_to_path LD_LIBRARY_PATH $PYTHIA8_DIR/lib
    add_to_path LD_LIBRARY_PATH $FCCPHYSICS/lib
elif [[ "$unamestr" == 'Darwin' ]]; then
    echo "Platform detected: Darwin"
    check_local_setup
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
add_to_path CMAKE_PREFIX_PATH $FCCDAG
if [ "$DELPHES_DIR" ]; then
    add_to_path CMAKE_PREFIX_PATH $DELPHES_DIR
fi

#!/bin/sh
if [[ $# -le 3 ]]; then
  echo "Usage: ./test_master.sh user branch workdirectory"
  exit 1
fi

user=${1}
branch=${2}
workdir=${3}

export podio_version=$branch
export physics_version=$branch
export edm_version=$branch
export release_version=$branch
export heppy_version=$branch

./build_fcc_stack.sh $user $workdir $workdir/install

# only test FCCSW on lxplus & co
if [[ `dnsdomainname` = 'cern.ch' ]] ; then
  ######################################################################
  echo "Test FCCSW-Delphes -> fcc-physics"
  ######################################################################
  cd FCCSW
  ./run gaudirun.py Sim/SimDelphesInterface/options/PythiaDelphes_config.py
  rc=$?; if [[ $rc != 0 ]]; then exit $rc; fi
  mv FCCDelphesOutput.root example.root
  $FCCPHYSICS/bin/fcc-physics-read-delphes
  rc=$?; if [[ $rc != 0 ]]; then exit $rc; fi
  cd ..
fi

######################################################################
echo "Test fcc-physics-pythia8 -> heppy"
######################################################################
cd heppy/test
$FCCPHYSICS/bin/fcc-pythia8-generate $FCCPHYSICS/share/ee_ZH_Zmumu_Hbb.txt
rc=$?; if [[ $rc != 0 ]]; then exit $rc; fi
heppy_loop.py Trash analysis_ee_ZH_cfg.py -f
rc=$?; if [[ $rc != 0 ]]; then exit $rc; fi
cd ../..

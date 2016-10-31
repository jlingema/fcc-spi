import urllib2 as urllib
import yaml
import re
import os
import subprocess
import argparse


def get_versions():
    url = 'https://raw.githubusercontent.com/jlingema/fcc-spi/docpage/docpage/_data/versions.yml'
    fobj = urllib.urlopen(url)
    versions = yaml.load(fobj.read())
    latest_idx = -1
    latest_version = "0.0.0"
    for i, v in enumerate(versions):
        vstring = v['version']
        if vstring != 'snapshot' and vstring > latest_version:
            latest_version = vstring
            latest_idx = i

    for dependency in versions[latest_idx]["dependencies"]:
        clean_name = dependency['name'].replace('fcc-', '')
        os.environ[clean_name+'_version'] = dependency['version']


parser = argparse.ArgumentParser("FCC release creator", formatter_class=argparse.ArgumentDefaultsHelpFormatter)
parser.add_argument('installdir', type=str, help='where to install')
args = parser.parse_args()

get_versions()
print args.installdir
subprocess.call(['./build_fcc_stack.sh', args.installdir])

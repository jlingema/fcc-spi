from __future__ import print_function
import yaml
import os
import sys

import urllib2 as urllib
import json
import datetime

post_header = """---
layout: post
title:  "FCCSW {tag}"
thisversion: "{name}"
---
### Version {name}"""

def get_release_notes(repo, tag):
    print('getting release notes for : ', repo, tag)
    url = 'https://api.github.com/repos/HEP-FCC/{repo}/releases/tags/{tag}'
    fobj = urllib.urlopen(url.format(repo=repo, tag=tag))
    return json.loads(fobj.read())["body"]


def get_gaudi_version(tag):
    url = 'https://raw.githubusercontent.com/HEP-FCC/FCCSW/{tag}/CMakeLists.txt'
    fobj = urllib.urlopen(url.format(tag=tag))
    for line in fobj:
        if "USE Gaudi" in line:
            _, __, v, ___ = line.split()
            return v

if __name__ == "__main__":
    env_keys = os.environ.keys()
    if not "release_name" in env_keys or os.environ["release_name"] == "snapshot":
        sys.exit(0)

    versions = {}
    fname = os.path.join("docpage", "_data", "versions.yml")
    with open("docpage/_data/versions.yml", 'r') as fobj:
        versions = yaml.load(fobj.read())

    cvmfs_path = "/cvmfs/fcc.cern.ch/sw/"
    afs_path = "/afs/cern.ch/exp/fcc/sw/"

    fccsw_name = os.environ["release_name"]
    fccsw_tag = 'v'+os.environ["release_name"]

    version = {}
    version["tag"] = fccsw_tag
    version["afs"] = afs_path + fccsw_name
    version["cvmfs"] = cvmfs_path + fccsw_name

    version["dependencies"] = []

    gaudi_version = get_gaudi_version(fccsw_tag)
    for dep in ["podio", "fcc-edm", "fcc-physics"]:
        name = dep
        if "-" in name:
            _, name = dep.split("-")
        v = os.environ[name + "_version"]
        tag = "v" + v
        version["dependencies"].append({
            "name": dep,
            "version": v,
            "tag": tag,
            "description": get_release_notes(dep, tag)
        })
    version["dependencies"] += [{
        "name": "lcg",
        "link": "http://lcgsoft.web.cern.ch/lcgsoft/release/"+os.environ["lcg_version"].replace("LCG_", ""),
        "version": os.environ["lcg_version"]
    }, {
        "name": "GAUDI",
        "link": "http://proj-gaudi.web.cern.ch/proj-gaudi/",
        "version": ""
    }]
    versions.append(version)
    with open(fname, 'w') as fobj:
        fobj.write(yaml.dump(versions))


    ### create blog post
    now = datetime.datetime.now()
    date_string = now.strftime("%Y-%m-%d")
    version_string = "version" + fccsw_name.replace(".", "")
    fname = os.path.join("docpage", "_posts", date_string + "-" + version_string + ".markdown")
    content = []
    content.append(post_header.format(tag=fccsw_tag, name=fccsw_name))

    content.append(get_release_notes("FCCSW", fccsw_tag))
    with open(fname, 'w') as fobj:
        fobj.write("\n".join(content))

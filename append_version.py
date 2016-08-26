import yaml
import argparse
import os
import datetime
import re
import sys

import urllib2 as urllib
import json
import base64


def get_release_notes(repo, tag):
    url = 'https://api.github.com/repos/HEP-FCC/{repo}/releases/tags/{tag}'
    fobj = urllib.urlopen(url.format(repo=repo, tag=tag))
    return json.loads(fobj.read())["body"]

def commit_updated_file():
    pass

def add_file(filename, content, repo, message):
    req_content = {"author": {"email": "j.lingemann@gmail.com", "name": "jlingema"}}
    req_content["message"] = message
    req_content["content"] = base64.b64encode(content)
    url = 'https://api.github.com/repos/jlingema/{repo}/contents/{fname}'
    print url.format(repo=repo, fname=filename), json.dumps(req_content)
    #request = urllib.Request(url.format(repo=repo, fname=filename),
    #                        json.dumps(req_content))


if __name__ == "__main__":
    add_file("test.txt", "blablablabla", "test", "test commit from script")
    # if os.env["release_name"] == "snapshot":
    #     sys.exit(0)
    # versions = {}
    # with open("docpage/_data/versions.yml", 'r') as fobj:
    #     versions = yaml.load(fobj.read())

    # cvmfs_path = "/cvmfs/fcc.cern.ch/sw/"
    # afs_path = "/afs/cern.ch/exp/fcc/sw/"

    # fccsw_name = os.env["fccsw_version"]
    # fccsw_tag = os.env["fccsw_rel"]

    # versions[fccsw_name] = {}
    # versions[fccsw_name]["tag"] = fccsw_tag
    # versions[fccsw_name]["afs"] = afs_path + fccsw_name
    # versions[fccsw_name]["cvmfs"] = cvmfs_path + fccsw_name

    # versions[fccsw_name]["dependencies"] = []
    # for dep in ["podio", "fcc-edm", "fcc-physics"]:
    #     name = dep
    #     if "-" in name:
    #         name = dep.split("-")
    #     tag = os.env[name + "_tag"]
    #     versions[fccsw_name]["dependencies"].append({
    #         "name": dep,
    #         "version": os.env[name + "_version"],
    #         "tag": tag,
    #         "description": get_release_notes(dep, tag)
    #     })
    # versions[fccsw_name]["dependencies"] = [{
    #     "name": "lcg",
    #     "link": "http://lcgsoft.web.cern.ch/lcgsoft/release/"+os.env["lcg_release"].replace("LCG_", ""),
    #     "version": os.env["lcg_release"]
    # }, {
    #     "name": "GAUDI",
    #     "link": "http://proj-gaudi.web.cern.ch/proj-gaudi/",
    #     "version": ""
    # }]

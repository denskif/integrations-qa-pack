import os
import re
import sys

import requests
import urllib3

import gitlab

TOKEN = os.getenv('PRIVATE_TOKEN')
GEN_PROJECT = os.getenv('GEN_PROJECT')
GITLAB_ADDRESS = 'https://gitlab.egt-ua.loc'


def get_gitlab_connection():
    session = requests.Session()
    session.verify = False
    urllib3.disable_warnings()
    return gitlab.Gitlab(GITLAB_ADDRESS, private_token=TOKEN, session=session)


def get_target_group_and_project(url):
    pattern = r"https:\/\/gitlab\.egt-ua\.loc\/apis\/gen\/(.*)"
    r = re.search(pattern, url)
    if r:
        path = r.group(1).split('/')
        if len(path) == 1:
            return None, path[0].lower()
        elif len(path) == 2:
            return path[0].lower(), path[1].lower()
    raise Exception(f'Wrong path: "{url}"')


def get_gen_group(gl):
    for gl_group in gl.groups.list(search='gen'):
        if gl_group.full_path == 'apis/gen':
            gen_group = gl_group
            break
    else:
        raise Exception('No apis/gen group.')
    return gen_group


def get_or_create_subgroup(gl, gen_group, target_subgroup):
    subgroups = gen_group.subgroups.list()
    for g in subgroups:
        if g.path == target_subgroup:
            print(f'Target subgroup "{target_subgroup}" exists\n')
            _subgroup = g
            break
    else:
        print('Subgroup creating')
        _subgroup = gl.groups.create({'name': target_subgroup, 'path': target_subgroup, 'parent_id': gen_group.id})
        print(f'Subgroup id:{_subgroup.id} name:{_subgroup.path} created\n')
    return gl.groups.get(_subgroup.id, lazy=True)  # need this to get full group-like api for subgroup


def touch_project(gl, subgroup, target_project):
    projects = subgroup.projects.list()
    for p in projects:
        if p.path == target_project:
            print(f'Project already exists:\n{p.web_url}\n\n')
            return
    else:
        print('Creating project')
        p = gl.projects.create({'name': target_project, 'namespace_id': subgroup.id})
        print(f'Project {p.web_url} created\n\n')


def main():
    gl = get_gitlab_connection()

    target_group, target_project = get_target_group_and_project(GEN_PROJECT)
    gen_group = get_gen_group(gl)
    if target_group:
        subgroup = get_or_create_subgroup(gl, gen_group, target_group)
    else:
        subgroup = gen_group

    touch_project(gl, subgroup, target_project)


if __name__ == '__main__':
    main()

import inspect
import os

NEXUS_USERNAME = os.getenv('REGISTRY_USER', 'no_user')
NEXUS_PASSWORD = os.getenv('REGISTRY_PASSWORD', 'no_password')
PACKAGE_NAME = os.getenv('PACKAGE_NAME', 'no_package_name')
VERSION = os.getenv('CI_COMMIT_TAG', 'no_version')
PYPI_REPO = os.getenv('PYPI_REPO', 'no_pypi')


def save_to_file(name, text):
    with open(name, 'w') as f:
        f.write(inspect.cleandoc(text) + '\n')
    print(f'{name} ready.')


def gen_pypirc():
    pypirc_t = f'''\
    [distutils]
    index-servers =
       nexus

    [nexus]
    repository = {PYPI_REPO}
    username = {NEXUS_USERNAME}
    password = {NEXUS_PASSWORD}
    '''

    save_to_file('/root/.pypirc', pypirc_t)


def gen_setup_py():
    setup_py_t = f"""
    import os
    from distutils.core import setup

    setup(
        name='{PACKAGE_NAME}',
        version='{VERSION}',
        description='Protobuf for {PACKAGE_NAME}',
        package_data={{'{PACKAGE_NAME}': ['py.typed', '*.pyi', '*.proto']}},
        include_package_data=True,
        packages=[pack[0] for pack in os.walk('{PACKAGE_NAME}')],
        install_requires=[],
        author='EGT Ukraine',
        author_email='no email',
    )
    """

    save_to_file('setup.py', setup_py_t)


def gen_manifest():
    manifest_t = f'''
    global-include {PACKAGE_NAME} *.txt *.py
    '''

    save_to_file('MANIFEST.in', manifest_t)


gen_pypirc()
gen_setup_py()
gen_manifest()

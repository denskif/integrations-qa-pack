import inspect
import os

NEXUS_USERNAME = os.getenv('NEXUS_USERNAME', 'no_user')
NEXUS_PASSWORD = os.getenv('NEXUS_PASSWORD', 'no_password')
PACKAGE_NAME = os.getenv('PACKAGE_NAME', 'no_package_name')
PACKAGE_SUFFIX = os.getenv('PACKAGE_SUFFIX', 'no_package_suffix')
VERSION = os.getenv('VERSION', 'no_version')
PYPI_REPO = os.getenv('PYPI_REPO', 'no_pypi')

print(f"Generating configs for {PACKAGE_NAME} version {VERSION}")


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
    requires = [
        'protobuf>=3.9.1',
        'googleapis-common-protos>=1.51.0',
    ]
    if PACKAGE_SUFFIX == '_async':
        requires.append('grpclib>=0.3.0')
    else:
        requires.append('grpcio>=1.23.0')

    requires_str = '\n'
    for l in requires:
        requires_str += ' ' * 12 + f"'{l}',\n"

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
        install_requires=[{requires_str}
        ],
        author='EGT Ukraine',
        author_email='no email',
    )
    """

    save_to_file('setup.py', setup_py_t)


def gen_manifest():
    manifest_t = f'''
    recursive-include {PACKAGE_NAME} *.proto
    '''

    save_to_file('MANIFEST.in', manifest_t)


gen_pypirc()
gen_setup_py()
gen_manifest()

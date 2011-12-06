#!/usr/bin/env python
"""Setup file for vista_utils"""

import os

# BEFORE importing distutils, remove MANIFEST. distutils doesn't properly
# update it when the contents of directories change.
if os.path.exists('MANIFEST'): os.remove('MANIFEST')

from distutils.core import setup

# Get version and release info, which is all stored in nitime/version.py
ver_file = os.path.join('.','vista_utils','version.py')
execfile(ver_file)

opts = dict(name=NAME,
            maintainer=MAINTAINER,
            maintainer_email=MAINTAINER_EMAIL,
            description=DESCRIPTION,
            long_description=LONG_DESCRIPTION,
            author=AUTHOR,
            author_email=AUTHOR_EMAIL,
            version=VERSION,
            packages=PACKAGES,
            requires=REQUIRES,
            )

# Only add setuptools-specific flags if the user called for setuptools, but
# otherwise leave it alone
import sys
if 'setuptools' in sys.modules:
    opts['zip_safe'] = False

# Now call the actual setup function
if __name__ == '__main__':
    setup(**opts)

"""nitime version/release information"""

ISRELEASED = False

# Format expected by setup.py and doc/source/conf.py: string of form "X.Y.Z"
_version_major = 0
_version_minor = 1
_version_micro = 'dev'
__version__ = "%s.%s.%s" % (_version_major, _version_minor, _version_micro)


## CLASSIFIERS = ["Development Status :: 3 - Alpha",
##                "Environment :: Console",
##                "Intended Audience :: Science/Research",
##                "License :: OSI Approved :: BSD License",
##                "Operating System :: OS Independent",
##                "Programming Language :: Python",
##                "Topic :: Scientific/Engineering"]

description = "vista_utils: utilities for interfacing with data from mrVista"

# Note: this long_description is actually a copy/paste from the top-level
# README.txt, so that it shows up nicely on PyPI.  So please remember to edit
# it only in one place and sync it correctly.
long_description = """
"""

NAME                = "vista_utils"
MAINTAINER          = "Ariel Rokem"
MAINTAINER_EMAIL    = "arokem@gmail.com"
DESCRIPTION         = description
LONG_DESCRIPTION    = long_description
AUTHOR              = "Ariel Rokem"
AUTHOR_EMAIL        = "arokem@gmail.com"
MAJOR               = _version_major
MINOR               = _version_minor
MICRO               = _version_micro
VERSION             = __version__
PACKAGES            = ['vista_utils']
REQUIRES            = ["numpy", "matplotlib", "scipy"]

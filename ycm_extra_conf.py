# This file is NOT licensed under the GPLv3, which is the license for the rest
# of YouCompleteMe.
#
# Here's the license text for this file:
#
# This is free and unencumbered software released into the public domain.
#
# Anyone is free to copy, modify, publish, use, compile, sell, or
# distribute this software, either in source code form or as a compiled
# binary, for any purpose, commercial or non-commercial, and by any
# means.
#
# In jurisdictions that recognize copyright laws, the author or authors
# of this software dedicate any and all copyright interest in the
# software to the public domain. We make this dedication for the benefit
# of the public at large and to the detriment of our heirs and
# successors. We intend this dedication to be an overt act of
# relinquishment in perpetuity of all present and future rights to this
# software under copyright law.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
# IN NO EVENT SHALL THE AUTHORS BE LIABLE FOR ANY CLAIM, DAMAGES OR
# OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
# ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
# OTHER DEALINGS IN THE SOFTWARE.
#
# For more information, please refer to <http://unlicense.org/>

import os
import os.path
import ycm_core
import re

log = open('/tmp/ycm.log', 'a')

# These are the compilation flags that will be used in case there's no
# compilation database set (by default, one is not set).
# CHANGE THIS LIST OF FLAGS. YES, THIS IS THE DROID YOU HAVE BEEN LOOKING FOR.
flags = [
'-Wall',
'-Wextra',
'-Werror',
'-Wno-unused-parameter',
'-Wno-long-long',
'-Wno-variadic-macros',
'-fexceptions',
# THIS IS IMPORTANT! Without a "-std=<something>" flag, clang won't know which
# language to use when compiling headers. So it will guess. Badly. So C++
# headers will be compiled as C headers. You don't want that so ALWAYS specify
# a "-std=<something>".
# For a C project, you would set this to something like 'c99' instead of
# 'c++11'.
'-std=gnu++14',
# ...and the same thing goes for the magic -x option which specifies the
# language that the files to be compiled are written in. This is mostly
# relevant for c++ headers.
# For a C project, you would set this to 'c' instead of 'c++'.
'-x',
'c++',
# See https://github.com/Valloric/YouCompleteMe#user-content-completion-doesnt-work-with-the-c-standard-library-headers
'-isystem',
'/usr/local/include'
'-isystem',
'/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/include/c++/v1'
'-isystem',
'/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/lib/clang/9.1.0/include'
'-isystem',
'/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/include'
'-isystem',
'/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX10.13.sdk/usr/include'
'-isystem',
'/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX10.13.sdk/System/Library/Frameworks '
]

def DirectoryOfThisScript():
  return os.path.dirname( os.path.abspath( __file__ ) )


# Set this to the absolute path to the folder (NOT the file!) containing the
# compile_commands.json file to use that instead of 'flags'. See here for
# more details: http://clang.llvm.org/docs/JSONCompilationDatabase.html
#
# You can get CMake to generate this file for you by adding:
#   set( CMAKE_EXPORT_COMPILE_COMMANDS 1 )
# to your CMakeLists.txt file.
#
# Most projects will NOT need to set this to anything; you can just change the
# 'flags' list of compilation flags. Notice that YCM itself uses that approach.
compilation_database_folder = DirectoryOfThisScript()

if os.path.exists( compilation_database_folder ):
  database = ycm_core.CompilationDatabase( compilation_database_folder )
else:
  database = None

SOURCE_EXTENSIONS = [ '.cpp', '.cxx', '.cc', '.c', '.m', '.mm' ]



def IsHeaderFile( filename ):
  extension = os.path.splitext( filename )[ 1 ]
  return extension in [ '.h', '.hxx', '.hpp', '.hh' ]


def GetCompilationInfoForFile( filename ):
  # The compilation_commands.json file generated by CMake does not have entries
  # for header files. So we do our best by asking the db for flags for a
  # corresponding source file, if any. If one exists, the flags for that file
  # should be good enough.
  if IsHeaderFile( filename ):
    basename = os.path.splitext( filename )[ 0 ]
    for extension in SOURCE_EXTENSIONS:
      replacement_file = basename + extension
      if os.path.exists( replacement_file ):
        compilation_info = database.GetCompilationInfoForFile(
          replacement_file )
        if compilation_info.compiler_flags_:
          return compilation_info
    return None
  return database.GetCompilationInfoForFile( filename )


PROEJCT_DEP_RE = re.compile("""(publicDep|privateDep)\('([^)]+)'\)""")
THIRD_PARTY_DEP_RE = re.compile(
    """(3rdPartyDep|3rdPartyDepForceLink)\('([^']+)'""")

VERSION_LINE_RE = re.compile("""version *= *'([^']+)'""")

def GetIncludePathsFor3rdParty(tp_lib_path):
    """Given the path to a third party lib (e.g. :third_party:cpp:eigen) return
    a list of directories to add to the include path."""
    repo_root = os.path.abspath(os.path.split(DirectoryOfThisScript())[0])
    # First find the version info for the lib
    assert tp_lib_path.startswith(':')
    build_path = os.path.join(repo_root, tp_lib_path[1:].replace(':', '/'),
                              'build.gradle')
    with open(build_path, 'r') as bf:
        version = None
        for line in bf:
            m = VERSION_LINE_RE.search(line)
            if m is not None:
                version = m.group(1)
                break
        if version is None:
            print('Unable to find version for', tp_lib_path,
                  file=log, flush=True)
            return []

    lib_name = tp_lib_path.split(':')[-1]
    include_dir = os.path.join(repo_root, '.install/OSX/Debug', lib_name,
                               version, 'include')
    print('Include dir for %s is %s' % (tp_lib_path, include_dir),
          file=log, flush=True)
    return [include_dir,]


def GetIncludePathsForFile(filename):
    """If we weren't able to get actual compile info from the DB we can parse
    the build.gradle and figure out what it depends on and then add that stuff
    to the include path.

    TODO: Parse 3rd party deps too and add them to the path as well.
    """
    cdir = os.path.split(filename)[0]
    found_build = False
    while cdir not in ('/', ''):
        build_gradle = os.path.join(cdir, 'build.gradle')
        if os.path.exists(build_gradle):
            found_build = True
            break
        else:
            cdir = os.path.split(cdir)[0]

    if not found_build:
        return []

    build_gradle_dir = os.path.split(build_gradle)[0]
    idirs = [os.path.join(build_gradle_dir, 'include'),
             os.path.join(build_gradle_dir, 'src')]
    repo_root = os.path.abspath(os.path.split(DirectoryOfThisScript())[0])
    print('repo root:', repo_root, file=log, flush=True)
    with open(build_gradle, 'r') as f:
        for line in f:
            m = PROEJCT_DEP_RE.search(line)
            if m is not None:
                proj = m.group(2)
                proj_dir = os.path.join(repo_root, proj[1:].replace(':', '/'))
                print('proj dir:', proj_dir, file=log, flush=True)
                idirs.append(os.path.join(proj_dir, 'include'))
            m = THIRD_PARTY_DEP_RE.search(line)
            if m is not None:
                for inc_dir in GetIncludePathsFor3rdParty(m.group(2)):
                    idirs.append(inc_dir)

    return list(map(lambda x: '-I' + x, idirs))
        


def FlagsForFile( filename, **kwargs ):
  default_return = {
      'flags': flags,
      'include_paths_relative_to_dir': DirectoryOfThisScript()
  }
  if not database:
    print('Database for %s not found.' % filename,
          file = log, flush = True)
    return default_return

  compilation_info = GetCompilationInfoForFile( filename )
  print('Compilation info for %s is %s' % (filename, compilation_info),
       file=log, flush=True)
  if not compilation_info:
    ret = default_return
    ret['flags'].extend(GetIncludePathsForFile(filename))
    return ret

  # Bear in mind that compilation_info.compiler_flags_ does NOT return a
  # python list, but a "list-like" StringVec object.
  final_flags = list( compilation_info.compiler_flags_ )
  final_flags.extend(flags)

  print('Final flags: %s' % final_flags, file=log, flush=True)

  try:
      sysroot_idx = final_flags.index('-isysroot')
      # Remove -isysroot and the next flag by deleting the same index twice
      del(final_flags[sysroot_idx])
      del(final_flags[sysroot_idx])
  except ValueError:
      pass

  return {
    'flags': final_flags,
    'include_paths_relative_to_dir': compilation_info.compiler_working_dir_
  }

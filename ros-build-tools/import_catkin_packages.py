#!/usr/bin/env python2


from __future__ import print_function

import catkin_pkg.package
from optparse import OptionParser
import os
import os.path
import subprocess
import urllib2
import urlparse
import yaml


PKGBUILD_TEMPLATE = """
pkgdesc='%(description)s'
url='http://www.ros.org/'

pkgname='ros-%(distro)s-%(arch_package_name)s'
pkgver='%(package_version)s'
arch=('i686' 'x86_64')
pkgrel=1
license=('%(license)s')
makedepends=('ros-build-tools')

ros_depends=(%(ros_package_dependencies)s)
depends=(${ros_depends[@]}
  %(other_dependencies)s)

source=()
md5sums=()

build() {
  source /opt/ros/%(distro)s/setup.bash
  if [ -d ${srcdir}/%(package_name)s ]; then
    GIT_DIR=${srcdir}/%(package_name)s/.git git fetch origin
    GIT_DIR=${srcdir}/%(package_name)s/.git git reset --hard release/%(package_name)s/${pkgver}
  else
    git clone -b release/%(package_name)s/${pkgver} %(package_url)s ${srcdir}/%(package_name)s
  fi
  mkdir ${srcdir}/build && cd ${srcdir}/build
  /usr/share/ros-build-tools/fix-python-scripts.sh ${srcdir}/%(package_name)s
  cmake ${srcdir}/%(package_name)s -DCMAKE_INSTALL_PREFIX=/opt/ros/%(distro)s -DPYTHON_EXECUTABLE=/usr/bin/python2 -DPYTHON_INCLUDE_DIR=/usr/include/python2.7 -DPYTHON_LIBRARY=/usr/lib/libpython2.7.so -DSETUPTOOLS_DEB_LAYOUT=OFF
  make
}

package() {
  cd "${srcdir}/build"
  make DESTDIR="${pkgdir}/" install
}
"""

class DistroDescription(object):

  def __init__(self, name, url):
    stream = urllib2.urlopen(url)
    self.name = name
    self._distro = yaml.load(stream)
    if self.name != self._distro['release-name']:
      raise 'ROS distro names do not match (%s != %s)' % (self.name, self._distro['release-name'])

  def packages(self):
    return [name for name in self._distro['repositories'].keys()]

  def package(self, name):
    return self._distro['repositories'][name]


def list_packages(distro_description):
  print(*distro_description.packages(), sep='\n')


### From http://code.activestate.com/recipes/577058/ (r2)
def query_yes_no(question, default="yes"):
  """Ask a yes/no question via raw_input() and return their answer.
  
  "question" is a string that is presented to the user.
  "default" is the presumed answer if the user just hits <Enter>.
      It must be "yes" (the default), "no" or None (meaning
      an answer is required of the user).

  The "answer" return value is one of "yes" or "no".
  """
  valid = {"yes":"yes",   "y":"yes",  "ye":"yes",
           "no":"no",     "n":"no"}
  if default == None:
      prompt = " [y/n] "
  elif default == "yes":
      prompt = " [Y/n] "
  elif default == "no":
      prompt = " [y/N] "
  else:
      raise ValueError("invalid default answer: '%s'" % default)
  while True:
      print(question + prompt)
      choice = raw_input().lower()
      if default is not None and choice == '':
          return default
      elif choice in valid.keys():
          return valid[choice]
      else:
          print("Please respond with 'yes' or 'no' (or 'y' or 'n').")


def parse_package_file(url):
  """
  Parses the package.xml file specified by `url`.
  
  Arguments:
  - `url`: Valid URL pointing to a package.xml file.
  """
  return catkin_pkg.package.parse_package_string(
    urllib2.urlopen(url).read())


def github_raw_url(repo_url, path, commitish):
  """
  Returns the URL of the file blob corresponding to `path` in the
  github repository `repo_url` in branch, commit or tag `commitish`.
  """
  url = urlparse.urlsplit(repo_url)
  return 'https://raw.%(host)s%(repo_path)s/%(branch)s/%(path)s' % {
    'host': url.hostname,
    'repo_path': url.path.replace('.git', ''),
    'branch': commitish,
    'path': path
    }


def get_arch_package_name(name):
  return name.replace('_', '-')


def get_ros_dependencies(distro, package):
  known_packages = distro.packages()
  return list(set([ dependency.name for dependency in package.build_depends + package.run_depends
                    if dependency.name in known_packages ]))


def get_non_ros_dependencies(distro, package):
  ros_dependencies = get_ros_dependencies(distro, package)
  return list(set([ dependency.name for dependency in package.build_depends + package.run_depends
                    if dependency.name not in ros_dependencies ]))


def fix_python_dependencies(packages):
  return [ package.replace('python-', 'python2-') for package in packages ]

def generate_pkgbuild(distro_description, package_name, directory,
                      exclude_dependencies=[], force=False):
  arch_package_name = get_arch_package_name(package_name)
  package = distro_description.package(package_name)
  package_version = package['version'].split('-')[0]
  package_url = package['url']
  package_description = parse_package_file(
    github_raw_url(package_url, 'package.xml', 'release/'+ package_name + '/' + package_version))
  ros_dependencies = [ dependency
                       for dependency in get_ros_dependencies(distro_description, package_description)
                       if dependency not in exclude_dependencies ]
  other_dependencies = [ dependency
                         for dependency in get_non_ros_dependencies(distro_description, package_description)
                         if dependency not in exclude_dependencies ]
  output_directory = os.path.join(directory, package_name)
  if not os.path.exists(output_directory):
    os.mkdir(output_directory)
  if os.path.exists(os.path.join(output_directory, 'PKGBUILD')):
    if not force and not query_yes_no(
      "Directory '%s' already contains a PKGBUILD file. Overwrite?" % (
        output_directory)):
      return
  with open(os.path.join(output_directory, 'PKGBUILD'), 'w') as pkgbuild:
    template_substitutions = {
      'distro': distro_description.name,
      'description': package_description.description,
      'license': ', '.join(package_description.licenses),
      'arch_package_name': arch_package_name,
      'package_name': package_name,
      'package_version': package_version,
      'package_url': package_url,
      'ros_package_dependencies': '\n  '.join(ros_dependencies),
      'other_dependencies': '  \n  '.join(fix_python_dependencies(other_dependencies))
      }
    pkgbuild.write(PKGBUILD_TEMPLATE % template_substitutions)


def main():
  parser = OptionParser(usage='usage: %prog [options] PACKAGE...')
  parser.add_option('--distro', default='groovy', metavar='distro',
                    help='Select the ROS distro to use.')
  parser.add_option('--list-packages', dest='list_packages', action='store_true',
                    default=False, help='Lists all available packages.')
  parser.add_option('--output-directory', metavar='output_directory', default='.',
                    help='The output directory. Packages are put into <output-directory>/<name>')
  parser.add_option(
    '--distro-url', metavar='distro_url',
    default='https://raw.github.com/ros/rosdistro/master/releases/%s.yaml',
    help='The URL of the distro description. %s is replaced by the actual distro name')
  parser.add_option(
    '--exclude-dependencies', metavar='exclude_dependencies',
    default='python-catkin-pkg',
    help='Comma-separated list of (source) package dependencies to exclude from the generated PKGBUILD file.')
  parser.add_option('-f', '--force', dest='force', action='store_true', default=False,
                    help='Always overwrite exiting PKGBUILD files.')
  options, args = parser.parse_args()

  distro_description = DistroDescription(
    options.distro, url=options.distro_url % options.distro)
  if options.list_packages:
    list_packages(distro_description)
    return
  elif args:
    for package in args:
      generate_pkgbuild(distro_description, package,
                        os.path.abspath(options.output_directory),
                        exclude_dependencies=options.exclude_dependencies,
                        force=options.force)
  else:
    parser.error('No packages specified.')


if __name__ == '__main__':
  main()

#!/usr/bin/env python


from optparse import OptionParser
import os
import os.path
import subprocess
import urllib.parse
import urllib.request
import yaml


PKGBUILD_TEMPLATE = """
pkgdesc='Fill me.'
url='http://www.ros.org/'

pkgname='ros-%(distro)s-%(package_name)s'
pkgver='%(package_version)s'
arch=('i686' 'x86_64')
pkgrel=1
license=('BSD')
makedepends=('ros-build-tools')

ros_depends=(%(ros_package_dependencies)s)
depends=(${ros_depends[@]})

source=()
md5sums=()

build() {
  source /opt/ros/%(distro)s/setup.bash
  git clone -b release/%(package_name)s/${pkgver} %(package_url)s %(package_name)s
  mkdir ${srcdir}/build && cd ${srcdir}/build
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
    stream = urllib.request.urlopen(url)
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
        choice = input().lower()
        if default is not None and choice == '':
            return default
        elif choice in valid.keys():
            return valid[choice]
        else:
            print("Please respond with 'yes' or 'no' (or 'y' or 'n').")


def generate_pkgbuild(distro_description, package_name, directory):
  package = distro_description.package(package_name)
  output_directory = os.path.join(directory, package_name)
  if not os.path.exists(output_directory):
    os.mkdir(output_directory)
  if os.path.exists(os.path.join(output_directory, 'PKGBUILD')):
    if not query_yes_no(
      "Directory '%s' already contains a PKGBUILD file. Overwrite?" % (
        output_directory)):
      return
  with open(os.path.join(output_directory, 'PKGBUILD'), 'w') as pkgbuild:
    template_substitutions = {
      'distro': distro_description.name,
      'package_name': package_name,
      'package_version': package['version'].split('-')[0],
      'package_url': package['url'],
      'ros_package_dependencies': 'todo',}
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
  options, args = parser.parse_args()

  distro_description = DistroDescription(
    options.distro, url=options.distro_url % options.distro)
  if options.list_packages:
    list_packages(distro_description)
    return
  elif args:
    for package in args:
      generate_pkgbuild(distro_description, package,
                        os.path.abspath(options.output_directory))
  else:
    parser.error('No packages specified.')


if __name__ == '__main__':
  main()

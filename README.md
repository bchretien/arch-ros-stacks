arch-ros-stacks
---------------

This is a fork of [zootboy](https://github.com/zootboy/arch-ros-stacks)'s fork of [hauptmech](https://github.com/hauptmech/arch-ros-stacks)'s fork of [moesenle](https://github.com/moesenle/arch-ros-stacks)'s very nice arch-ros-stacks.

I am maintaining Hydro/Indigo packages for Arch Linux. Please e-mail me with any suggestions, comments or package requests:

\<chretien at lirmm dot fr\>

### Python version

Starting with Indigo, Python 3 support is added to ROS. However, since most non-core packages are not Python 3 ready yet, we will continue using Python 2 for Indigo.

### How to contribute

If you want to contribute, simply fork this repository, create or update some packages, and make a pull request afterwards.

The script that automates most of the work is `import_catkin_packages.py` available in `dependencies/ros-build-tools`. To list its options:

```shell
$ python2 import_catkin_packages.py --help
```

To list all available packages:

```shell
$ python2 import_catkin_packages.py --distro=hydro --list | less
```

You can also provide the output directory when listing packages, in order to see the ones that have not been generated yet:

```shell
$ python2 import_catkin_packages.py --distro=hydro --output-directory=/path/to/arch-ros-stacks/hydro --list | less
```


To add a new official package called `package_foo` recursively:

```shell
$ python2 import_catkin_packages.py --distro=hydro --output-directory=/path/to/arch-ros-stacks/hydro -r package_foo
```

To simply update `package_foo`:


```shell
$ python2 import_catkin_packages.py --distro=hydro --output-directory=/path/to/arch-ros-stacks/hydro -u package_foo
```

To recursively "force update" `package_foo`:

```shell
$ python2 import_catkin_packages.py --distro=hydro --output-directory=/path/to/arch-ros-stacks/hydro -rfu package_foo
```

The Python version can also be chosen:
```shell
$ python2 import_catkin_packages.py --python-version=2.7 --distro=hydro --output-directory=...
```

Note that the default behavior is to fetch release information from the [official rosdistro distribution.yaml](https://github.com/ros/rosdistro/blob/master/hydro/distribution.yaml).

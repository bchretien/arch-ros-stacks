arch-ros-stacks
---------------

This is a fork of [zootboy](https://github.com/zootboy/arch-ros-stacks)'s fork of [hauptmech](https://github.com/hauptmech/arch-ros-stacks)'s fork of [moesenle](https://github.com/moesenle/arch-ros-stacks)'s very nice arch-ros-stacks.

I am maintaining Hydro packages for Arch Linux. Please e-mail me with any suggestions, comments or package requests:

\<chretien at lirmm dot fr\>

### How to contribute

If you want to contribute, simply fork this repository, create or update some packages, and make a pull request afterwards.

The script that automates most of the work is `import_catkin_packages.py` available in `dependencies/ros-build-tools`. To list its options:

```shell
$ python2 import_catkin_packages.py --help
```

To add a new official package called `package_foo` recursively:

```shell
$ python2 import_catkin_packages.py --distro=hydro --output-directory=/path/to/arch-ros-stacks/hydro -r package_foo
```

To simply update `package_foo`:


```shell
$ python2 import_catkin_packages.py --distro=hydro --output-directory=/path/to/arch-ros-stacks/hydro -u package_foo
```

Note that the default behavior is to fetch release information from the [official rosdistro distribution.yaml](https://github.com/ros/rosdistro/blob/master/hydro/distribution.yaml).

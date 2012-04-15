#!/bin/sh

export ROS_ROOT=/opt/ros/electric/ros
export PATH=${ROS_ROOT}/bin:${PATH}
export PYTHONPATH=${ROS_ROOT}/core/roslib/src:${PYTHONPATH}
export ROS_PACKAGE_PATH=/opt/ros/electric/stacks
if [ ! "$ROS_MASTER_URI" ] ; then export ROS_MASTER_URI=http://localhost:11311 ; fi

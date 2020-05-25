#!/bin/bash


GEM=`gem build deadpool.gemspec | egrep -o "(deadpool.*gem)"`
gem push $GEM
rm $GEM

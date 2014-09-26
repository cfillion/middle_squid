#!/bin/sh

GEM_HOME=$(ruby -e 'puts Gem.user_dir')
exec $GEM_HOME/bin/middle_squid $*

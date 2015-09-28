#!/bin/bash

cd "`dirname "$0"`"/../
#if ! [ -f epic.rb ]; then
#	echo "Run this script from the top level directory." >&2
#	exit 1
#fi

export JRUBY_OPTS=$(
  echo -n $(
    for i in $JRUBY_OPTS; do
      echo $i;
    done |
    grep -v -- --1.9
  )
)

rdoc --debug \
  --main epic.rb \
  --charset=UTF-8 \
  --encoding=UTF-8 \
  --title=ePIC \
  --tab-width=2 \
  --format=hanna \
  --all \
  --output=public/docs/epic \
  --force-output \
  epic*.rb djinn*.rb *.rdoc
#  $GEM_HOME/gems/rack*/lib $GEM_HOME/gems/json*/lib \
#  $GEM_HOME/gems/sequel*/lib
#  --exclude=public/docs/epic \
#  --exclude=attic \

# rdoc \
  # --main dav.rb \
  # --encoding=UTF-8 \
  # --title=ePIC \
  # --format=darkfish \
  # --output=rdoc \
  # --exclude=rdoc \
  # --all \
  # --line-numbers \
  # --exclude='some_gems' \
  # . $GEM_HOME/gems/*/lib

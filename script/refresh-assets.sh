#!/bin/bash
rake assets:clobber && RAILS_ENV=production rake assets:precompile && echo "done"

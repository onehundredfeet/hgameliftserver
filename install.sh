#!/bin/bash

# Setup logging
log_file="/local/game/install.log"
exec > >(tee $log_file) 2>&1

echo "Starting install script..."

find .

which node
which python

#!/bin/bash
cd $(dirname "$0")
source test-utils.sh

# Verify toolchain is installed and on PATH
check "java" java -version
check "gradle" gradle --version
check "mvn" mvn -version
check "gh" gh --version
check "claude" claude --version
check "node" node --version

reportResults

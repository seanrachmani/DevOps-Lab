#!/usr/bin/env bash
#(use bash to run this script)

#change bash actions. e for  exit if something fails:
set -e


cleanup() {
    echo "Removing the test container..."
    docker rm -f devops-test
}

echo "Building the test image..."
docker build -t devops-lab:test .

echo "Starting the test container..."
docker run -d --name devops-test -p 127.0.0.1:8081:8000 devops-lab:test

#if we are about to exit, cleanup
trap cleanup EXIT

#wait until the website responds
echo "Waiting for the website..."
curl --fail --silent --show-error \
    --retry 10 --retry-all-errors --retry-delay 1 \
    --connect-timeout 2 --max-time 3 \
    --output /dev/null \
    http://localhost:8081

#run the Python test against the temporary container.
echo "Running the tests..."
BASE_URL=http://localhost:8081 python3 tests/test_website.py

echo "Build and tests passed!"



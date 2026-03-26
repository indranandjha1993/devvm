#!/bin/bash
# Generate traffic to PHP demo app
while true; do
  curl -s http://localhost:9253/ > /dev/null 2>&1
  curl -s http://localhost:9253/api/items > /dev/null 2>&1
  sleep $(shuf -i 1-3 -n 1)
done

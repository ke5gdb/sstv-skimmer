#!/bin/sh

nohup python3 /poster.py "$@" > /upload.log 2>&1 &
#!/bin/bash
ps -ef | grep turnilo | grep -v grep | awk '{print $2}' | xargs kill -15
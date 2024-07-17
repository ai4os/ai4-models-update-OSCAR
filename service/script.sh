#!/bin/sh

cd acc-services
mv $INPUT_FILE_PATH $INPUT_FILE_PATH.json
python acc.py $INPUT_FILE_PATH.json

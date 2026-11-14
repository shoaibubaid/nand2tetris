#!/bin/bash

sources=$(find chips -name "*.v")
test="${1}"

iverilog -o sim $sources $test && vvp sim
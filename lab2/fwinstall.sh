#!/bin/sh

st-flash write firmware.bin 0x08000000
st-flash reset


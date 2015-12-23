#!/bin/bash

export PATH=$(realpath toolchain/usr/bin):/usr/local/bin:$PATH
sudo -u enerccio make clean 
sudo -u enerccio make all 

pushd disk
./update_image.sh
popd

#sudo -u enerccio qemu-system-x86_64 -hdc disk.img -m 128 -s -cpu Haswell,+pdpe1gb -d int,cpu_reset
sudo -u enerccio qemu-system-x86_64 -hdc disk.img -m 128 -s -d int,cpu_reset

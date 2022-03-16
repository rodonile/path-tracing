# VPP with Path Tracing installation instructions

- The code for the VPP version with the Path Tracing patch is available [here](https://github.com/path-tracing/vpp). Since compilation can be quite cumbersome, pre-compiled binaries (.deb) can be downloaded from [this link](<vpp_binaries_URL>), and if you want to quickly test out our pipeline we suggest using them. 

- Install all the debian packages:

        sudo dpkg -i *.deb

- If you get some errors there might be some additional dependencies you might have to install (they should be pointed out by dpkg if installation fails)
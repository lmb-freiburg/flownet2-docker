
default: flownet2

.PHONY: flownet2

flownet2:
	docker build -f Dockerfile -t flownet2 . --build-arg CUDA_DRIVER_VER=`modinfo nvidia | grep "^version:" | cut -d':' -f2 | sed 's/ //g'`


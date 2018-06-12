SHELL:=/bin/bash

default: flownet2

.PHONY: flownet2

flownet2:
	docker build                    \
	       -f Dockerfile            \
	       -t flownet2              \
	       --build-arg uid=$$UID    \
	       --build-arg gid=$$GROUPS \
	       .


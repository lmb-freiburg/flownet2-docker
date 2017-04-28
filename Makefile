
default: flownet2

.PHONY: flownet2

flownet2:
	docker build -f Dockerfile -t flownet2 .


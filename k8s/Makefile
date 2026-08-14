.PHONY: check up deploy forward down clean

check:
	./scripts/check-prerequisites.sh

up:
	./scripts/setup-minikube.sh

deploy: up
	./scripts/build-and-deploy.sh

forward:
	./scripts/forward.sh

down:
	./scripts/teardown.sh

clean:
	./scripts/teardown.sh --full

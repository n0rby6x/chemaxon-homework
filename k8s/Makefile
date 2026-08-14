.PHONY: check minikube build deploy test stop clean

check:
	./scripts/check-tools.sh

minikube:
	minikube start --driver=docker

build:
	minikube image build -t rest-service:local .

deploy:
	kubectl apply -f k8s/
	kubectl rollout status deployment/rest-service --timeout=120s

test:
	./scripts/test.sh

stop:
	minikube stop

clean:
	kubectl delete -f k8s/ --ignore-not-found
	minikube stop
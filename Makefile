.PHONY: init

init:
	docker run -it --rm -v $(shell pwd):/src -v ~/.ssh:/root/.ssh -w /src --env-file $(shell pwd)/.env hashicorp/terraform:0.15.0 init

.PHONY: validate

validate:
	docker run -it --rm -v $(shell pwd):/src -v ~/.ssh:/root/.ssh -w /src  --env-file $(shell pwd)/.env hashicorp/terraform:0.15.0 validate

.PHONY: plan

plan:
	docker run -it --rm -v $(shell pwd):/src -v ~/.ssh:/root/.ssh -w /src  --env-file $(shell pwd)/.env hashicorp/terraform:0.15.0 plan

.PHONY: apply

apply:
	docker run -it --rm -v $(shell pwd):/src -v ~/.ssh:/root/.ssh -w /src  --env-file $(shell pwd)/.env hashicorp/terraform:0.15.0 apply

.PHONY: destroy

destroy:
	docker run -it --rm -v $(shell pwd):/src -v ~/.ssh:/root/.ssh -w /src  --env-file $(shell pwd)/.env hashicorp/terraform:0.15.0 destroy

.PHONY: cli

cli:
	docker run -it --rm -v $(shell pwd):/src -v ~/.ssh:/root/.ssh -w /src  --env-file $(shell pwd)/.env --entrypoint /bin/sh hashicorp/terraform:0.15.0

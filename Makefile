project = services

all: build

run: 
	docker-compose -p $(project) up

start: 
	docker-compose -p $(project) up -d

stop: 
	docker-compose -p $(project) stop
	docker-compose -p $(project) rm

test:
	docker-compose -p $(project) run $(project) rspec src/app_test.rb

build:
	docker build -t cncflora/$(project) .

push:
	docker push cncflora/$(project)


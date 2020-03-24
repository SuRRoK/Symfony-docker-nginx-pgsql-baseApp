up: docker-up
init: docker-down-clear docker-pull docker-build docker-up myapp-init
test: myapp-test

docker-up:
	docker-compose up -d

docker-down:
	docker-compose down --remove-orphans

docker-down-clear:
	docker-compose down -v --remove-orphans

docker-pull:
	docker-compose pull

docker-build:
	docker-compose build

myapp-init: myapp-composer-install

myapp-composer-install:
	docker-compose run --rm myapp-php-cli composer install

myapp-test:
	docker-compose run --rm myapp-php-cli php bin/phpunit

build-production:
	docker build --pull --file=appdocker/production/nginx.docker --tag ${REGISTRY_ADDRESS}/myapp-nginx:${IMAGE_TAG} myapp
	docker build --pull --file=appdocker/production/php-fpm.docker --tag ${REGISTRY_ADDRESS}/myapp-php-fpm:${IMAGE_TAG} myapp
	docker build --pull --file=appdocker/production/php-cli.docker --tag ${REGISTRY_ADDRESS}/myapp-php-cli:${IMAGE_TAG} myapp
	docker build --pull --file=appdocker/production/postgres.docker --tag ${REGISTRY_ADDRESS}/myapp-postgres:${IMAGE_TAG} myapp

push-production:
	docker push ${REGISTRY_ADDRESS}/myapp-nginx:${IMAGE_TAG}
	docker push ${REGISTRY_ADDRESS}/myapp-php-fpm:${IMAGE_TAG}
	docker push ${REGISTRY_ADDRESS}/myapp-php-cli:${IMAGE_TAG}
	docker push ${REGISTRY_ADDRESS}/myapp-postgres:${IMAGE_TAG}

deploy-production:
	ssh -o StrictHostKeyChecking=no ${PRODUCTION_HOST} -p ${PRODUCTION_PORT} 'rm -rf docker-compose.yml .env'
	scp -o StrictHostKeyChecking=no -P ${PRODUCTION_PORT} docker-compose-production.yml ${PRODUCTION_HOST}:docker-compose.yml
	ssh -o StrictHostKeyChecking=no ${PRODUCTION_HOST} -p ${PRODUCTION_PORT} 'echo "REGISTRY_ADDRESS=${REGISTRY_ADDRESS}" >> .env'
	ssh -o StrictHostKeyChecking=no ${PRODUCTION_HOST} -p ${PRODUCTION_PORT} 'echo "IMAGE_TAG=${IMAGE_TAG}" >> .env'
	ssh -o StrictHostKeyChecking=no ${PRODUCTION_HOST} -p ${PRODUCTION_PORT} 'echo "MYAPP_APP_SECRET=${MYAPP_APP_SECRET}" >> .env'
	ssh -o StrictHostKeyChecking=no ${PRODUCTION_HOST} -p ${PRODUCTION_PORT} 'echo "MYAPP_DB_PASSWORD=${MYAPP_DB_PASSWORD}" >> .env'
	ssh -o StrictHostKeyChecking=no ${PRODUCTION_HOST} -p ${PRODUCTION_PORT} 'docker-compose pull'
	ssh -o StrictHostKeyChecking=no ${PRODUCTION_HOST} -p ${PRODUCTION_PORT} 'docker-compose --build -d'
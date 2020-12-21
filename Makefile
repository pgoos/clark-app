ifdef APP
	APP_NAME = $(shell echo $(APP) | tr A-Z a-z)
else
	APP_NAME = clark
endif

FOCUSED_APP = $(shell sed -n 's/^focused_specs_brand: //p' config/settings.yml)
BACKEND_IMAGE = clark_backend_$(APP_NAME)
FRONTEND_IMAGE = clark_frontend
dc = docker-compose -f ./docker-compose.local.yml
dcbr = $(dc) run --service-ports --use-aliases --rm backend
dcfr = $(dc) run --service-ports --use-aliases --rm frontend

export APP_NAME
export BACKEND_IMAGE
export FRONTEND_IMAGE
export FOCUSED_APP

# Database
db_prepare: ensure_dirs
		$(dcbr) 'bundle exec rails db:create db:structure:load'
db_drop: ensure_dirs
		$(dcbr) 'bundle exec rails db:drop'
db_migrate: ensure_dirs
		$(dcbr) 'bundle exec rails db:migrate && sed -i"" "/idle_in_transaction_session_timeout/d" db/structure.sql'
db_seed: ensure_dirs
		$(dcbr) 'bundle exec rails db:seed && bundle exec rake admin:setup white_label:build_admin_permissions'
db_reset: db_drop db_prepare db_migrate db_seed

# Backend
backend_server: ensure_dirs
		$(dcbr) 'bundle exec rails server -b 0.0.0.0'
backend_console: ensure_dirs
		$(dcbr) 'bundle exec rails console'
backend_dev: ensure_dirs
		$(dcbr) 'bash'
backend_fixtures: ensure_dirs
		$(dcbr) 'bundle exec rake cms:sites:setup cms:sync:import FROM=de TO=de'
backend_gems: ensure_dirs
		$(dcbr) 'bundle install'
backend_node: ensure_dirs
		$(dcbr) 'yarn install --non-interactive'
backend_build_base:
		docker build -f Dockerfile.backend.local -t clark_backend_base:latest --target clark_backend_base ./docker
backend_build_label:
		docker build --build-arg app=$(APP_NAME) -f Dockerfile.backend.local -t $(BACKEND_IMAGE) --target clark_backend_label ./docker
backend_build: backend_build_base backend_build_label backend_gems backend_node
backend_setup: backend_build db_prepare db_migrate db_seeds backend_fixtures
backend_reset: backend_build db_reset backend_fixtures
backend_refresh: backend_build db_migrate

# Frontend
frontend_server: ensure_dirs
		$(dcfr) 'ember server -H 0.0.0.0 -p 4200'
frontend_dev: ensure_dirs
		$(dcfr) 'bash'
frontend_node: ensure_dirs
		$(dcfr) 'yarn install --non-interactive'
frontend_build_base:
		docker build -f Dockerfile.frontend.local -t $(FRONTEND_IMAGE) --target clark_frontend ./docker
frontend_build: frontend_build_base frontend_node

# Utilities
clean:
		$(dc) down --remove-orphans --volumes
ensure_dirs:
		bin/dev/docker_volume_paths
watch_emails:
		bundle exec guard -P shell

# Brand specs
test_focused_brand: test_main test_focused_brand_context
test_brand: test_main test_brand_context
test_main:
		bundle exec rspec --exclude-pattern "(lib\/lifters\/domain|models)\/.*"  \
		--tag ~@browser --tag ~@integration --tag ~@fail \
		--tag ~@timeout --tag ~@slow --tag ~@clark_with_master_data
test_focused_brand_context:
		APP=$(FOCUSED_APP) bundle exec rspec --tag $(FOCUSED_APP)_context
test_brand_context:
		APP=$(APP) bundle exec rspec --tag $(APP)_context

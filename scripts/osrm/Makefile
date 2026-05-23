REGION = asia
COUNTRY = japan
AREA = kanto
PLATFORM = linux/amd64
SOURCE_DIR = $(CURDIR)/.data/$(AREA)
OSRM_FNAME = $(AREA)-latest.osrm
PBF_FNAME = $(AREA)-latest.osm.pbf
PBF_URL = https://download.geofabrik.de/$(REGION)/$(COUNTRY)/$(PBF_FNAME)

DOCKER_IMAGE = osrm/osrm-backend
DESTINATION_DIR = /data
OSRM_DESTINATION_FPATH = $(DESTINATION_DIR)/$(OSRM_FNAME)
DOCKER_MOUNT = $(SOURCE_DIR):$(DESTINATION_DIR)
PORT = 5000

all: setup run

setup:
	@echo "AREA: $(AREA)"
	if [ ! -e "$(SOURCE_DIR)" ]; then mkdir -p "$(SOURCE_DIR)"; fi
	if [ ! -e "$(SOURCE_DIR)/$(PBF_FNAME)" ]; then wget -P "$(SOURCE_DIR)" $(PBF_URL); fi
	docker pull $(DOCKER_IMAGE)
	docker run --platform $(PLATFORM) -t -v "$(DOCKER_MOUNT)" $(DOCKER_IMAGE) osrm-extract -p /opt/car.lua "$(DESTINATION_DIR)/$(PBF_FNAME)"
	docker run --platform $(PLATFORM) -t -v "$(DOCKER_MOUNT)" $(DOCKER_IMAGE) osrm-partition "$(OSRM_DESTINATION_FPATH)"
	docker run --platform $(PLATFORM) -t -v "$(DOCKER_MOUNT)" $(DOCKER_IMAGE) osrm-customize "$(OSRM_DESTINATION_FPATH)"

run:
	@echo "AREA: $(AREA)"
	docker run --platform $(PLATFORM) -t -i -p $(PORT):5000 -v "$(DOCKER_MOUNT)" $(DOCKER_IMAGE) osrm-routed --algorithm mld "$(OSRM_DESTINATION_FPATH)"

background:
	@echo "AREA: $(AREA)"
	docker run --platform $(PLATFORM) --detach -t -i -p $(PORT):5000 -v "$(DOCKER_MOUNT)" $(DOCKER_IMAGE) osrm-routed --algorithm mld "$(OSRM_DESTINATION_FPATH)"

CONTENT_FILES := $(shell find content/ -type f)
DATA_FILES := $(shell find data/ -type f)
LAYOUTS := $(shell find layouts/ -type f)
RESOURCES := $(shell find resources/ -type f)
STATIC_FILES := $(shell find static/ -type f)

public: $(CONTENT_FILES) $(DATA_FILES) $(LAYOUTS) $(RESOURCES) $(STATIC_FILES) config.toml
	hugo

.PHONY: upload
upload: public
	if [ -d /Volumes/p111.lithium.hosting/var/www/html/blog/ ]; then \
		rsync --delete --recursive --progress public/ /Volumes/p111.lithium.hosting/var/www/html/blog/; \
	else \
		echo "Mount the WebDAV drive first."; \
		exit 1; \
	fi


.PHONY: clean
clean:
	rm -rf public

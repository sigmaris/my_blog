CONTENT_FILES := $(shell find content/ -type f)
DATA_FILES := $(shell find data/ -type f)
LAYOUTS := $(shell find layouts/ -type f)
RESOURCES := $(shell find resources/ -type f)
STATIC_FILES := $(shell find static/ -type f)

.PHONY: upload
upload: public
	rsync --delete --recursive --progress public/ sigmaris.info:public_html/blog/

public: $(CONTENT_FILES) $(DATA_FILES) $(LAYOUTS) $(RESOURCES) $(STATIC_FILES) config.toml
	hugo

.PHONY: clean
clean:
	rm -rf public

CONTENT_FILES := $(shell find content/ -type f)
DATA_FILES := $(shell find data/ -type f)
LAYOUTS := $(shell find layouts/ -type f)
RESOURCES := $(shell find resources/ -type f)
STATIC_FILES := $(shell find static/ -type f)
SERVER := p109.lithium.hosting

public: $(CONTENT_FILES) $(DATA_FILES) $(LAYOUTS) $(RESOURCES) $(STATIC_FILES) config.toml
	hugo

.PHONY: upload
upload: public
	export LFTP_PASSWORD="$$(security find-internet-password -a sigmaris@sigmaris.info -l $(SERVER) -r ftps -g -w)" ; \
	lftp -c "set ftp:ssl-force true && open --user sigmaris@sigmaris.info --env-password ftp://$(SERVER) && mirror --reverse --continue --delete --only-newer --verbose public /var/www/html/blog"

.PHONY: clean
clean:
	rm -rf public

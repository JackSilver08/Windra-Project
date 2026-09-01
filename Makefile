.PHONY: help desktop dev go check iso clean

help:
	@echo "Windra 0.2 Desktop Alpha targets:"
	@echo "  make desktop - configure/build shell + native alpha apps"
	@echo "  make dev     - build and launch Windra Shell windowed"
	@echo "  make go      - build Go services"
	@echo "  make check   - run Go tests/vet + shell script syntax checks"
	@echo "  make iso     - build Debian live ISO skeleton"
	@echo "  make clean   - remove build artifacts"

desktop:
	cmake -S . -B build -G Ninja
	cmake --build build

dev:
	./tools/dev-run.sh

go:
	mkdir -p build/bin
	cd services/webapps && go build -trimpath -o ../../build/bin/windra-webapp .
	cd services/health && go build -trimpath -o ../../build/bin/windra-health .

check:
	cd services/webapps && go test ./... && go vet ./...
	cd services/health && go test ./... && go vet ./...
	bash -n tools/*.sh iso/auto/config iso/config/includes.chroot/usr/bin/windra-session

iso:
	./tools/build-iso.sh

clean:
	rm -rf build iso/.build

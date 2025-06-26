FROM ubuntu:22.04 AS build
WORKDIR /app
RUN apt-get update -y
RUN apt-get install -y build-essential make
COPY include/ ./include/
COPY scripts/ ./scripts/
COPY share/ ./share/
COPY src/ ./src/
COPY tests/ ./tests/
COPY Makefile ./Makefile
RUN ./scripts/install-dev-dependencies.sh
RUN ./scripts/install-dependencies.sh
RUN ./scripts/make.sh release

FROM ubuntu:22.04 AS runtime
WORKDIR /app
COPY --from=build /app/dist/ ./dist/
COPY scripts/install-dependencies.sh ./scripts/install-dependencies.sh
RUN ./scripts/install-dependencies.sh
RUN rm -rf ./scripts
ENTRYPOINT [ "./dist/bin/microui" ]

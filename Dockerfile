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
RUN ./scripts/make.sh dev-dependencies
RUN ./scripts/make.sh dependencies
RUN ./scripts/make.sh build-release

FROM ubuntu:22.04 AS runtime
WORKDIR /app
RUN apt-get update -y
RUN apt-get install -y build-essential make
COPY --from=build /app/dist/ ./dist/
COPY scripts/ ./scripts/
COPY Makefile ./Makefile
RUN ./scripts/make.sh dependencies
ENTRYPOINT [ "./scripts/microui.sh" ]
CMD ["server"]

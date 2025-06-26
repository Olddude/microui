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
RUN sudo ./scripts/dependencies_dev.sh
RUN sudo ./scripts/dependencies.sh
RUN ./scripts/build_release.sh

FROM ubuntu:22.04 AS runtime
WORKDIR /app
RUN apt-get update -y
RUN apt-get install -y build-essential make
COPY ./scripts/ ./scripts/
RUN sudo ./scripts/dependencies.sh
COPY --from=build /app/dist/ ./dist/
CMD [ "./scripts/run.sh" ]

FROM ubuntu:22.04 AS build
RUN apt-get update -y

FROM ubuntu:22.04 AS runtime
COPY ./dist/ /usr/
RUN chown -R root:root /usr/
RUN chmod +x /usr/bin/crust
CMD [ "/usr/bin/microui", "server" ]

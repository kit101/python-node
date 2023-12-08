from python:3.7

LABEL maintainer="kit101 <qkssk1711@163.com>"

ARG NODE_MAJOR=16

RUN apt-get update && apt-get install -y ca-certificates curl gnupg
RUN mkdir -p /etc/apt/keyrings; \
    curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key  | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg; \
    echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_$NODE_MAJOR.x nodistro main"  > /etc/apt/sources.list.d/nodesource.list; \
    apt-get update;
RUN apt-get install -y nodejs
RUN npm install -g yarn cnpm
RUN echo node `node -v` && echo npm `npm -v` && echo yarn `yarn -v` && python -V

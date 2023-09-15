from python:3.7

RUN apt-get update && apt-get install -y curl
RUN curl -sL https://deb.nodesource.com/setup_16.x | bash -
RUN apt-get install -y nodejs
RUN npm install yarn -g
# RUN npm install cnpm -g
# RUN echo node `node -v` && echo npm `npm -v` && echo yarn `yarn -v` && python -V && cnpm -v
RUN echo node `node -v` && echo npm `npm -v` && echo yarn `yarn -v` && python -V

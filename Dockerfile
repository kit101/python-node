from python:3.7

RUN curl -sL https://deb.nodesource.com/setup_14.x | bash -
RUN apt-get install -y nodejs
RUN npm install yarn -g
RUN echo node `node -v` && echo npm `npm -v` && echo yarn `yarn -v` && python -V

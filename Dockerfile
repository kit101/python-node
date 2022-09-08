from python:3.7

RUN curl -sL https://deb.nodesource.com/setup_14.x | bash -
RUN apt-get install -y nodejs
RUN npm install yarn -g
RUN node -v && npm -v && python -V

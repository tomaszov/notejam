FROM node:16.3.0-alpine3.13
RUN mkdir -p /opt/notejam
COPY ./app/notejam /opt/notejam
WORKDIR /opt/notejam
RUN npm install
RUN node db.js
ENTRYPOINT ["./entrypoint.sh"]



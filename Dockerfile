FROM node:18-alpine

WORKDIR /app

COPY my-medusa-store/ /app

RUN cd /app

RUN npx medusa develop

EXPOSE 7001 9000
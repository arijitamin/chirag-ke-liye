FROM node:18-alpine

WORKDIR /app

COPY my-medusa-store/ .

RUN npx medusa develop

EXPOSE 7001 9000
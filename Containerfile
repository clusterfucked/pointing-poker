FROM docker.io/node:lts-alpine as build

EXPOSE 3000
WORKDIR /var/usr/app

COPY package.json ./
COPY yarn.lock ./

RUN yarn install --frozen-lockfile

COPY . .

RUN yarn build

USER node

ENTRYPOINT [ "yarn" ]
CMD [ "start" ]

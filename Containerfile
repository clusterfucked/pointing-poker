FROM docker.io/node:24-alpine as build

EXPOSE 3000
WORKDIR /app

COPY package.json yarn.lock ./
RUN yarn install --frozen-lockfile

RUN mkdir -p /prod/node_modules && \
  cp package.json yarn.lock /prod/ && \
  cd /prod && \
  yarn install --production --frozen-lockfile

COPY . .

RUN yarn build

FROM gcr.io/distroless/nodejs24-debian13:nonroot

EXPOSE 3000
WORKDIR /app

COPY --from=build /app/__sapper__/build ./__sapper__/build
COPY --from=build /app/static ./static
COPY --from=build /prod/node_modules ./node_modules

USER nonroot

CMD [ "__sapper__/build" ]

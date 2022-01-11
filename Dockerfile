#Built using # Node.js image
FROM node:12.22.7-bullseye-slim
ENV APP_ROOT /src

# Specify the working directory to $ APP_ROOT
WORKDIR $APP_ROOT

COPY package.json $APP_ROOT


#Install dependent packages
RUN yarn install

COPY . $APP_ROOT

CMD ["yarn", "start"]

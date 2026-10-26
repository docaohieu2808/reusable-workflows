# syntax=docker/dockerfile:1
FROM node:24.22.1-alpine3.24
WORKDIR /app
COPY package.json index.js ./
USER node
EXPOSE 3000
HEALTHCHECK --interval=5s --timeout=3s --retries=5 CMD wget -qO- http://127.0.0.1:3000/ || exit 1
CMD ["node", "index.js"]

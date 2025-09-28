FROM node:20-alpine
WORKDIR /usr/src/app
COPY app/package.json ./
COPY app/ ./
ENV PORT=8080
EXPOSE 8080
HEALTHCHECK --interval=03s --timeout=3s --retries= \
 CMD wget -q0 http://127.0.1:8080/health || exit 1
CMD [ "npm", "start" ]

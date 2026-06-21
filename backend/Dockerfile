FROM node:20-alpine

WORKDIR /app

# Build deps for better-sqlite3 native bindings
RUN apk add --no-cache python3 make g++

COPY package*.json ./
RUN npm install --omit=dev

COPY . .

RUN mkdir -p data
ENV NODE_ENV=production
ENV DB_PATH=/app/data/timesheet.db

EXPOSE 4000

CMD ["sh", "-c", "node src/db/migrate.js && node src/db/seed.js && node src/server.js"]

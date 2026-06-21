# Builds the Flutter app for the WEB target and serves it via nginx.
# Mobile (Android/iOS) builds cannot run inside Docker — for device/emulator
# testing, run `flutter run` locally instead (see root README).

FROM ghcr.io/cirruslabs/flutter:stable AS build
WORKDIR /app
COPY . .
RUN flutter pub get
# Point the web build at the backend service name from docker-compose.
RUN flutter build web --release --dart-define=API_BASE_URL=http://localhost:4000

FROM nginx:alpine
COPY --from=build /app/build/web /usr/share/nginx/html
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]

# Build AOT binary
FROM dart:stable AS build
WORKDIR /app
COPY pubspec.* ./
RUN dart pub get
COPY . .
RUN dart pub get --offline
RUN dart compile exe bin/server.dart -o bin/server

# Minimal runtime with Stockfish for vs-computer mode
FROM debian:bookworm-slim
RUN apt-get update \
  && apt-get install -y --no-install-recommends ca-certificates stockfish \
  && rm -rf /var/lib/apt/lists/* \
  && (command -v stockfish >/dev/null || ln -sf /usr/games/stockfish /usr/local/bin/stockfish)
WORKDIR /app
COPY --from=build /app/bin/server /app/server
ENV PORT=8080
ENV STOCKFISH_PATH=stockfish
EXPOSE 8080
CMD ["/app/server"]

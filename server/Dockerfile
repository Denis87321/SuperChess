# Repo-root context. Used when dockerContext is "." (see render.yaml).
# Keeps path dependency packages/super_chess_engine available at build time.

FROM dart:stable AS build
WORKDIR /app

COPY packages/super_chess_engine ./packages/super_chess_engine
COPY server/pubspec.yaml server/pubspec.lock ./server/
WORKDIR /app/server
RUN dart pub get

COPY server/ ./
RUN dart pub get --offline
RUN dart compile exe bin/server.dart -o bin/server

FROM debian:bookworm-slim
RUN apt-get update \
  && apt-get install -y --no-install-recommends ca-certificates stockfish \
  && rm -rf /var/lib/apt/lists/* \
  && (command -v stockfish >/dev/null || ln -sf /usr/games/stockfish /usr/local/bin/stockfish)
WORKDIR /app
COPY --from=build /app/server/bin/server /app/server
ENV PORT=8080
ENV STOCKFISH_PATH=stockfish
EXPOSE 8080
CMD ["/app/server"]

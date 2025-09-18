ARG RUBY_VERSION=3.3.6
FROM docker.io/library/ruby:$RUBY_VERSION-slim AS base

WORKDIR /rails

# Install base packages
RUN printf "\033[1;33m⚡ Installation des dépendances système de base... ⚡\033[0m\n" && \
    apt-get update -qq && \
    apt-get install --no-install-recommends -y curl libjemalloc2 libvips postgresql-client && \
    rm -rf /var/lib/apt/lists /var/cache/apt/archives && \
    printf "\033[1;33m⚡ ✅ Dépendances système installées avec succès ⚡\033[0m\n"

ENV RAILS_ENV="production" \
    BUNDLE_DEPLOYMENT="1" \
    BUNDLE_PATH="/usr/local/bundle" \
    BUNDLE_WITHOUT="development"

# Throw-away build stage
FROM base AS build

# Dev tools
RUN printf "\033[1;33m⚡ Installation des outils de développement... ⚡\033[0m\n" && \
    apt-get update -qq && \
    apt-get install --no-install-recommends -y build-essential git libpq-dev libyaml-dev node-gyp pkg-config python-is-python3 && \
    rm -rf /var/lib/apt/lists /var/cache/apt/archives && \
    printf "\033[1;33m⚡ ✅ Outils de développement installés ⚡\033[0m\n"

# Node.js
ARG NODE_VERSION=22.14.0
ENV PATH=/usr/local/node/bin:$PATH
RUN printf "\033[1;33m⚡ Installation de Node.js ${NODE_VERSION}... ⚡\033[0m\n" && \
    curl -sL https://github.com/nodenv/node-build/archive/master.tar.gz | tar xz -C /tmp/ && \
    /tmp/node-build-master/bin/node-build "${NODE_VERSION}" /usr/local/node && \
    rm -rf /tmp/node-build-master && \
    printf "\033[1;33m⚡ ✅ Node.js ${NODE_VERSION} installé ⚡\033[0m\n" && \
    node --version && npm --version

# Gems
COPY Gemfile Gemfile.lock ./
RUN printf "\033[1;33m⚡ Installation des gems Ruby... ⚡\033[0m\n" && \
    bundle install && \
    rm -rf ~/.bundle/ "${BUNDLE_PATH}"/ruby/*/cache "${BUNDLE_PATH}"/ruby/*/bundler/gems/*/.git && \
    bundle exec bootsnap precompile --gemfile && \
    printf "\033[1;33m⚡ ✅ Gems Ruby installées ⚡\033[0m\n"

# JS packages
COPY package.json ./
ARG GOOGLE_MAPS_KEY
ENV GOOGLE_MAPS_KEY=$GOOGLE_MAPS_KEY

RUN printf "\033[1;33m⚡ Installation des dépendances JavaScript... ⚡\033[0m\n" && \
    npm install --omit=dev && \
    npm run build && \
    printf "\033[1;33m⚡ ✅ Dépendances JavaScript installées et buildées ⚡\033[0m\n"

# Code
COPY . .
RUN printf "\033[1;33m⚡ ✅ Code de l'application copié ⚡\033[0m\n"

# Bootsnap
RUN printf "\033[1;33m⚡ Précompilation Bootsnap... ⚡\033[0m\n" && \
    bundle exec bootsnap precompile app/ lib/ && \
    printf "\033[1;33m⚡ ✅ Bootsnap précompilé ⚡\033[0m\n"

# Assets
RUN printf "\033[1;33m⚡ Précompilation des assets... ⚡\033[0m\n" && \
    SECRET_KEY_BASE_DUMMY=1 ./bin/rails assets:precompile && \
    printf "\033[1;33m⚡ ✅ Assets précompilés ⚡\033[0m\n"

# Clean
RUN printf "\033[1;33m⚡ Nettoyage des fichiers de build... ⚡\033[0m\n" && \
    rm -rf node_modules && \
    printf "\033[1;33m⚡ ✅ Nettoyage terminé ⚡\033[0m\n"

# Final image
FROM base
RUN printf "\033[1;33m⚡ 🚀 Construction de l'image finale... ⚡\033[0m\n"

COPY --from=build "${BUNDLE_PATH}" "${BUNDLE_PATH}"
COPY --from=build /rails /rails
RUN printf "\033[1;33m⚡ ✅ Artifacts copiés dans l'image finale ⚡\033[0m\n"

# Non-root user
RUN groupadd --system --gid 1000 rails && \
    useradd rails --uid 1000 --gid 1000 --create-home --shell /bin/bash && \
    chown -R rails:rails db log storage tmp && \
    printf "\033[1;33m⚡ ✅ Utilisateur 'rails' configuré ⚡\033[0m\n"
USER 1000:1000

ENTRYPOINT ["/rails/bin/docker-entrypoint"]

EXPOSE 80
RUN printf "\033[1;33m⚡ 🎯 Image prête ! Accessible sur le port 80 ⚡\033[0m\n"

CMD ["./bin/thrust", "./bin/rails", "server"]

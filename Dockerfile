# # syntax=docker/dockerfile:1
# # check=error=true

# # This Dockerfile is designed for production, not development. Use with Kamal or build'n'run by hand:
# # docker build -t flipflapp_fullstack .
# # docker run -d -p 80:80 -e RAILS_MASTER_KEY=<value from config/master.key> --name flipflapp_fullstack flipflapp_fullstack

# # For a containerized dev environment, see Dev Containers: https://guides.rubyonrails.org/getting_started_with_devcontainer.html

# # Make sure RUBY_VERSION matches the Ruby version in .ruby-version
# ARG RUBY_VERSION=3.3.6
# FROM docker.io/library/ruby:$RUBY_VERSION-slim AS base

# # Rails app lives here
# WORKDIR /rails

# # Install base packages
# RUN echo "➡️ Installation des dépendances système de base..." && \
#     apt-get update -qq && \
#     apt-get install --no-install-recommends -y curl libjemalloc2 libvips postgresql-client && \
#     rm -rf /var/lib/apt/lists /var/cache/apt/archives && \
#     echo "✅ Dépendances système de base installées avec succès"

# # Set production environment
# ENV RAILS_ENV="production" \
#     BUNDLE_DEPLOYMENT="1" \
#     BUNDLE_PATH="/usr/local/bundle" \
#     BUNDLE_WITHOUT="development"

# # Throw-away build stage to reduce size of final image
# FROM base AS build

# # Install packages needed to build gems and node modules
# RUN echo "➡️ Installation des outils de développement pour la compilation..." && \
#     apt-get update -qq && \
#     apt-get install --no-install-recommends -y build-essential git libpq-dev libyaml-dev node-gyp pkg-config python-is-python3 && \
#     rm -rf /var/lib/apt/lists /var/cache/apt/archives && \
#     echo "✅ Outils de développement installés avec succès"

# # Install JavaScript dependencies
# ARG NODE_VERSION=22.14.0
# ENV PATH=/usr/local/node/bin:$PATH
# RUN echo "➡️ Installation de Node.js version ${NODE_VERSION}..." && \
#     curl -sL https://github.com/nodenv/node-build/archive/master.tar.gz | tar xz -C /tmp/ && \
#     /tmp/node-build-master/bin/node-build "${NODE_VERSION}" /usr/local/node && \
#     rm -rf /tmp/node-build-master && \
#     echo "✅ Node.js ${NODE_VERSION} installé avec succès" && \
#     node --version && npm --version

# # Install application gems
# COPY Gemfile Gemfile.lock ./
# RUN echo "➡️ Installation des gems Ruby (bundle install)..." && \
#     bundle install && \
#     rm -rf ~/.bundle/ "${BUNDLE_PATH}"/ruby/*/cache "${BUNDLE_PATH}"/ruby/*/bundler/gems/*/.git && \
#     bundle exec bootsnap precompile --gemfile && \
#     echo "✅ Gems Ruby installées avec succès" && \
#     echo "📦 $(bundle list | wc -l) gems installées"

# # Install node modules
# COPY package.json ./
# RUN echo "➡️ Installation des dépendances JavaScript (npm install)..." && \
#     npm install --omit=dev && \
#     echo "✅ Dépendances JavaScript installées avec succès" && \
#     echo "📦 $(ls node_modules | wc -l) packages JavaScript installés"

# # Copy application code
# COPY . .
# RUN echo "✅ Code de l'application copié dans le conteneur"

# # Precompile bootsnap code for faster boot times
# RUN echo "➡️ Précompilation du cache Bootsnap pour des démarrages plus rapides..." && \
#     bundle exec bootsnap precompile app/ lib/ && \
#     echo "✅ Cache Bootsnap précompilé avec succès"

# # Precompiling assets for production without requiring secret RAILS_MASTER_KEY
# RUN echo "➡️ Précompilation des assets (CSS, JS, images) pour la production..." && \
#     SECRET_KEY_BASE_DUMMY=1 ./bin/rails assets:precompile && \
#     echo "✅ Assets précompilés avec succès" && \
#     echo "📊 Taille des assets: $(du -sh public/assets 2>/dev/null || echo 'N/A')"

# # Clean up node_modules to reduce image size
# RUN echo "➡️ Nettoyage des fichiers de développement..." && \
#     rm -rf node_modules && \
#     echo "✅ Fichiers de développement supprimés (node_modules)"


# # Final stage for app image
# FROM base
# RUN echo "🚀 Construction de l'image finale de production..."

# # Copy built artifacts: gems, application
# COPY --from=build "${BUNDLE_PATH}" "${BUNDLE_PATH}"
# COPY --from=build /rails /rails
# RUN echo "✅ Artifacts de build copiés dans l'image finale"

# # Run and own only the runtime files as a non-root user for security
# RUN echo "➡️ Configuration de l'utilisateur non-root pour la sécurité..." && \
#     groupadd --system --gid 1000 rails && \
#     useradd rails --uid 1000 --gid 1000 --create-home --shell /bin/bash && \
#     chown -R rails:rails db log storage tmp && \
#     echo "✅ Utilisateur 'rails' configuré avec succès"
# USER 1000:1000

# # Entrypoint prepares the database.
# ENTRYPOINT ["/rails/bin/docker-entrypoint"]

# # Start server via Thruster by default, this can be overwritten at runtime
# EXPOSE 80
# RUN echo "🎯 Image prête ! L'application sera accessible sur le port 80"
# RUN echo "📋 Résumé de l'image:"
# RUN echo "   - Ruby: $(ruby --version)"
# RUN echo "   - Rails: $(bundle exec rails --version 2>/dev/null || echo 'N/A')"
# RUN echo "   - Environnement: ${RAILS_ENV}"
# RUN echo "   - Utilisateur: rails (UID 1000)"
# RUN echo "✨ Construction terminée avec succès !"

# CMD ["./bin/thrust", "./bin/rails", "server"]
# syntax=docker/dockerfile:1
# check=error=true

# Dockerfile production (Kamal ou build'n'run manuel)
# docker build -t flipflapp_fullstack .
# docker run -d -p 80:80 -e RAILS_MASTER_KEY=<config/master.key> --name flipflapp_fullstack flipflapp_fullstack

ARG RUBY_VERSION=3.3.6
FROM docker.io/library/ruby:$RUBY_VERSION-slim AS base

WORKDIR /rails

# Install base packages
RUN printf "\033[1;33m➡️ Installation des dépendances système de base...\033[0m\n" && \
    apt-get update -qq && \
    apt-get install --no-install-recommends -y curl libjemalloc2 libvips postgresql-client && \
    rm -rf /var/lib/apt/lists /var/cache/apt/archives && \
    printf "\033[1;32m✅ Dépendances système installées avec succès\033[0m\n"

ENV RAILS_ENV="production" \
    BUNDLE_DEPLOYMENT="1" \
    BUNDLE_PATH="/usr/local/bundle" \
    BUNDLE_WITHOUT="development"

# Throw-away build stage
FROM base AS build

# Dev tools
RUN printf "\033[1;33m➡️ Installation des outils de développement...\033[0m\n" && \
    apt-get update -qq && \
    apt-get install --no-install-recommends -y build-essential git libpq-dev libyaml-dev node-gyp pkg-config python-is-python3 && \
    rm -rf /var/lib/apt/lists /var/cache/apt/archives && \
    printf "\033[1;32m✅ Outils de développement installés\033[0m\n"

# Node.js
ARG NODE_VERSION=22.14.0
ENV PATH=/usr/local/node/bin:$PATH
RUN printf "\033[1;33m➡️ Installation de Node.js ${NODE_VERSION}...\033[0m\n" && \
    curl -sL https://github.com/nodenv/node-build/archive/master.tar.gz | tar xz -C /tmp/ && \
    /tmp/node-build-master/bin/node-build "${NODE_VERSION}" /usr/local/node && \
    rm -rf /tmp/node-build-master && \
    printf "\033[1;32m✅ Node.js ${NODE_VERSION} installé\033[0m\n" && \
    node --version && npm --version

# Gems
COPY Gemfile Gemfile.lock ./
RUN printf "\033[1;33m➡️ Installation des gems Ruby...\033[0m\n" && \
    bundle install && \
    rm -rf ~/.bundle/ "${BUNDLE_PATH}"/ruby/*/cache "${BUNDLE_PATH}"/ruby/*/bundler/gems/*/.git && \
    bundle exec bootsnap precompile --gemfile && \
    printf "\033[1;32m✅ Gems Ruby installées\033[0m\n"

# JS packages
COPY package.json ./
RUN printf "\033[1;33m➡️ Installation des dépendances JavaScript...\033[0m\n" && \
    npm install --omit=dev && \
    printf "\033[1;32m✅ Dépendances JavaScript installées\033[0m\n"

# Code
COPY . .
RUN printf "\033[1;32m✅ Code de l'application copié\033[0m\n"

# Bootsnap
RUN printf "\033[1;33m➡️ Précompilation Bootsnap...\033[0m\n" && \
    bundle exec bootsnap precompile app/ lib/ && \
    printf "\033[1;32m✅ Bootsnap précompilé\033[0m\n"

# Assets
RUN printf "\033[1;33m➡️ Précompilation des assets...\033[0m\n" && \
    SECRET_KEY_BASE_DUMMY=1 ./bin/rails assets:precompile && \
    printf "\033[1;32m✅ Assets précompilés\033[0m\n"

# Clean
RUN printf "\033[1;33m➡️ Nettoyage des fichiers de build...\033[0m\n" && \
    rm -rf node_modules && \
    printf "\033[1;32m✅ Nettoyage terminé\033[0m\n"

# Final image
FROM base
RUN printf "\033[1;36m🚀 Construction de l'image finale...\033[0m\n"

COPY --from=build "${BUNDLE_PATH}" "${BUNDLE_PATH}"
COPY --from=build /rails /rails
RUN printf "\033[1;32m✅ Artifacts copiés dans l'image finale\033[0m\n"

# Non-root user
RUN groupadd --system --gid 1000 rails && \
    useradd rails --uid 1000 --gid 1000 --create-home --shell /bin/bash && \
    chown -R rails:rails db log storage tmp && \
    printf "\033[1;32m✅ Utilisateur 'rails' configuré\033[0m\n"
USER 1000:1000

ENTRYPOINT ["/rails/bin/docker-entrypoint"]

EXPOSE 80
RUN printf "\033[1;36m🎯 Image prête ! Accessible sur le port 80\033[0m\n"

CMD ["./bin/thrust", "./bin/rails", "server"]

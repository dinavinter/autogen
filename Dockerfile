FROM ghcr.io/dinavinter/autogen:0.2.15 as autogen
 
ENV BIN=/home/autogen/.local/bin

# Set the path
ENV PATH="${BIN}:${PATH}"

# set python path
ENV PYTHONPATH="${BIN}:/autogen:${PYTHONPATH}"

FROM node:20-slim AS base
ENV PNPM_HOME="/pnpm"
ENV PATH="$PNPM_HOME:$PATH"
RUN corepack enable

FROM autogen AS studio-pip
COPY . /src
WORKDIR /home/autogen
#RUN sudo pip install .
#RUN sudo pip install . -t /home/autogen
#WORKDIR /home/autogen
RUN --mount=type=cache,target=/root/.cache/pip  \
    sudo pip install /src 
RUN --mount=type=cache,target=/root/.cache/pip  \
    sudo pip install /src/samples/apps/autogen-studio

RUN autogenstudio version | echo --stdin
 
FROM base AS studio-deps
COPY /samples/apps/autogen-studio/frontend/package.json /src/studio/frontend/package.json
COPY /samples/apps/autogen-studio/frontend/yarn.lock /src/studio/frontend/yarn.lock
WORKDIR /src/studio/frontend
RUN --mount=type=cache,id=yarn,target=$YARN_CACHE_FOLDER   \
    yarn install --prod --frozen-lockfile 

FROM base as studio-build 
#RUN --mount=type=cache,id=yarn-cache,target=$YARN_CACHE_FOLDER  \
#    yarn install --frozen-lockfile \
COPY /samples/apps/autogen-studio/frontend/package.json /src/studio/frontend/package.json
COPY /samples/apps/autogen-studio/frontend/yarn.lock /src/studio/frontend/yarn.lock

WORKDIR /src/studio/frontend

RUN yarn install --frozen-lockfile

COPY --from=studio-pip /src/samples/apps/autogen-studio /src/studio
 
RUN yarn build


FROM python:3.11-slim

# Set the path
ENV PATH="${BIN}:${PATH}"

# set python path
ENV PYTHONPATH="${BIN}:/autogen:${PYTHONPATH}"

COPY --from=studio-pip /home/autogen /home/autogen
COPY --from=studio-pip /src/samples/apps/autogen-studio /home/autogen/studio
COPY --from=studio-build /src/studio/autogenstudio/web /home/autogen/studio/autogenstudio/web

WORKDIR /home/autogen
RUN --mount=type=cache,target=/root/.cache/pip  \
      pip install /home/autogen/studio
RUN autogenstudio version | echo --stdin
RUN rm -rf /home/autogen/studio 
RUN autogenstudio version

EXPOSE 8081

CMD [ "autogenstudio", "ui", "--host", "0.0.0.0", "--port", "8081", "--appdir", "/home/autogen/workspace"]



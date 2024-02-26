#FROM ghcr.io/dinavinter/autogen:0.2.15 as autogen
FROM python:3.11-slim as autogen
ENV BIN=/home/autogen/.local/bin
ENV BIN_STUDIO=/home/autogen/.local/bin/autogenstudio

# Set the path
ENV PATH="${BIN}:${PATH}"

# set python path
ENV PYTHONPATH="${BIN}:/autogen:${PYTHONPATH}"
ENV PYTHONPATH="${BIN_STUDIO}:/autogenstudio:${PYTHONPATH}"

FROM node:20-slim AS base
ENV PNPM_HOME="/pnpm"
ENV PATH="$PNPM_HOME:$PATH"
RUN corepack enable

 
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

COPY /samples/apps/autogen-studio /src/studio
 
RUN yarn build


FROM autogen AS studio-pip
USER root
COPY . /src
#COPY --from=studio-build /src/studio/autogenstudio/web /src/samples/apps/autogen-studio/autogenstudio/web
RUN pip install build
RUN pip install setuptools-scm
#RUN sudo pip install .
#RUN sudo pip install . -t /home/autogen
#WORKDIR /home/autogen
#RUN --mount=type=cache,target=/root/.cache/pip  \
#      pip install /src  
#RUN --mount=type=cache,target=/root/.cache/pip  \
#      pip install /src/samples/apps/autogen-studio  

RUN --mount=type=cache,target=/dist  \
      python -m build -o /dist/autogen /src

RUN --mount=type=cache,target=/dist  \
      python -m build -w -o /dist/autogenstudio /src/samples/apps/autogen-studio   

WORKDIR /home/autogen

RUN --mount=type=cache,target=/root/.cache/pip  \
      pip install autogen -f /dist/ 

RUN --mount=type=cache,target=/root/.cache/pip  \
      pip install autogenstudio -f /dist/ 

RUN  autogenstudio version  



FROM studio-pip

# Set the environment variables
#ENV BIN=/home/autogen/.local/bin
#ENV BIN_STUDIO=/home/autogen/.local/bin/autogenstudio
#
### Set the path
##ENV PATH="${BIN}:${PATH}"
##ENV PATH="${BIN_STUDIO}:${PATH}"
##
### set python path
##ENV PYTHONPATH="${BIN}:/autogen:${PYTHONPATH}"
##ENV PYTHONPATH="${BIN_STUDIO}:/autogenstudio:${PYTHONPATH}"

#COPY --from=studio-pip /home/autogen /home/autogen
#COPY --from=studio-pip /dist /dist
#RUN --mount=type=cache,target=/root/.cache/pip  \
#      pip install autogen -f /dist/ 
#
#RUN --mount=type=cache,target=/root/.cache/pip  \
#      pip install autogenstudio -f /dist/ 

#RUN  autogenstudio version  


#COPY --from=studio-pip /src/samples/apps/autogen-studio /home/autogen/studio
#COPY --from=studio-build /src/studio/autogenstudio/web /home/autogen/studio/autogenstudio/web
#RUN #autogenstudioversion  

#WORKDIR /home/autogen
#RUN --mount=type=cache,target=/root/.cache/pip  \
#      pip install /home/autogen/studio -t $BIN
#RUN autogenstudio version | echo --stdin
#RUN rm -rf /home/autogen/studio 
#RUN autogenstudio version
# Set the path
ENV PATH="/home/autogen/.local/bin:${PATH}"

# set python path
ENV PYTHONPATH="/home/autogen/.local/bin:/autogen:${PYTHONPATH}"

RUN rm -rf /src
EXPOSE 8081

CMD [ "autogenstudio", "ui", "--host", "0.0.0.0", "--port", "8081", "--appdir", "/home/autogen/workspace"]
#CMD [ "/bin/bash" ]

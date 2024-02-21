#FROM python:3.11-slim-bookworm
FROM nikolaik/python-nodejs:python3.11-nodejs21	

RUN apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        software-properties-common sudo\
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

RUN npm install --global pnpm

# Setup a non-root user 'autogen' with sudo access
RUN adduser --disabled-password --gecos '' autogen
RUN adduser autogen sudo
RUN echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

USER autogen
WORKDIR /home/autogen


RUN pip install --upgrade pip
RUN pip install pyautogen[teachable,lmm,retrievechat,mathchat,blendsearch] autogenra
RUN pip install numpy pandas matplotlib seaborn scikit-learn requests urllib3 nltk pillow pytest beautifulsoup4
RUN pip install autogen

## install nodejs
ENV PNPM_HOME="/pnpm"
ENV PATH="$PNPM_HOME:$PATH"
RUN sudo corepack enable


# install front deps

WORKDIR /home/autogen/frontend
COPY frontend/package.json .
RUN sudo pnpm add -D gatsby-cli 
RUN sudo pnpm i
 
# install backend deps 
WORKDIR /home/autogen
RUN pip install pydantic fastapi typer uvicorn arxiv

#COPY requirements.txt .
#COPY pyproject.toml .
#
#RUN pip install -r requirements.txt 
                 
 
# build backend
COPY . .

WORKDIR /home/autogen 
 
# build frontend
WORKDIR /home/autogen/frontend
RUN pnpm run build


# Set the path
ENV PATH="/home/autogen/.local/bin:${PATH}"

# set python path
ENV PYTHONPATH="/home/autogen/.local/bin:/autogen:${PYTHONPATH}"

#test add autogenstudio in the PATH

RUN autogenstudio version

EXPOSE 8081

CMD [ "autogenstudio", "ui", "--host", "0.0.0.0", "--port", "8081", "--appdir", "/home/autogen/workspace"]
 

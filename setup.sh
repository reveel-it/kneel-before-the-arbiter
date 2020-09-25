python3 -m venv venv
venv/bin/pip install -U pip
venv/bin/pip install -r requirements.txt
# do the same thing as brownie init
mkdir -p build/contracts
mkdir -p build/deployments
mkdir -p build/interfaces
mkdir -p contracts
mkdir -p interfaces
mkdir -p reports
mkdir -p scripts
mkdir -p tests
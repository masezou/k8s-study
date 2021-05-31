REM Bulding Kind Cluster
REM kind create cluster --name k10-demo --image kindest/node:v1.19.11 --wait 600s
REM kind create cluster --name k10-demo --image kindest/node:v1.20.7 --wait 600s
REM kind create cluster --name k10-demo --image kindest/node:v1.21.1 --wait 600s

kind create cluster --name k10-demo --image kindest/node:v1.19.11 --wait 600s --config=config.yml

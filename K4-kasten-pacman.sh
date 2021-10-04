#!/usr/bin/env bash

NAMESPACE=pacman

kubectl -n ${NAMESPACE}  annotate deployment mongo kanister.kasten.io/blueprint='mongo-hooks'

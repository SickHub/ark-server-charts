#!/bin/sh

(cd charts
helm package ark-cluster
)

mv ./charts/ark-cluster-*.tgz ./docs/
helm repo index ./docs --url https://drpsychick.github.io/ark-cluster-chart/

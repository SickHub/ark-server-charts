#!/bin/sh

function bumpChartVersion() {
  v=$(grep '^version:' ./charts/$1/Chart.yaml | awk -F: '{print $2}' | tr -d ' ')
  patch=${v/*.*./}
  nv=${v/%$patch/}$((patch+1))
  sed -i "" -e "s/version: .*/version: $nv/" charts/$1/Chart.yaml
}

# checkout github-pages
git checkout gh-pages || exit
git pull

for c in ark-cluster; do
  [ -z "$(git status -s ./charts/$c/Chart.yaml)" ] && bumpChartVersion $c
  (cd charts; helm package $c)
  mv ./charts/$c-*.tgz ./docs/
done

helm repo index ./docs --url https://drpsychick.github.io/ark-server-charts/

git add ./docs
git commit -m "publish charts" -av
git push

# switch back to master and merge
git checkout master
git pull
git merge -m "merge gh-pages" gh-pages
git push

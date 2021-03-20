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
git merge --squash -m 'update from master' master
git push

for c in ark-cluster; do
  [ -z "$(git status -s ./charts/$c/Chart.yaml)" ] && bumpChartVersion $c
  (cd charts; helm package $c)
  mv ./charts/$c-*.tgz ./docs/
done

helm repo index ./docs --url https://drpsychick.github.io/ark-server-charts/

git add .
git commit -m "publish charts" -av
git push

# switch back to master and merge
git checkout master
git pull
git merge --squash -m "publish charts" gh-pages
<<<<<<< HEAD
git commit -m "publish charts" -av
=======
<<<<<<< HEAD
=======
git commit -m "publish charts" -av
>>>>>>> master
>>>>>>> gh-pages
git push

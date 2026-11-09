#!/bin/sh
# 공개 웹사이트용 docs/index.html 생성 (index.html 본문을 완전한 HTML 문서로 감싼다)
cd "$(dirname "$0")"
mkdir -p docs
{
  printf '<!doctype html>\n<html lang="ko">\n<head>\n<meta charset="utf-8">\n<meta name="viewport" content="width=device-width,initial-scale=1,viewport-fit=cover">\n</head>\n<body>\n'
  cat index.html
  printf '\n</body>\n</html>\n'
} > docs/index.html
echo "docs/index.html 생성 완료"

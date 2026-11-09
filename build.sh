#!/bin/sh
# 공개 웹사이트용 docs/index.html 생성 (index.html을 완전한 HTML 문서로 감싼다)
# - index.html 맨 앞의 <title>·<link>·<style>은 <head>로, 본문·스크립트는 <body>로 보낸다
# - 미리보기 이미지(og.png)는 og-image.html을 1200x630으로 캡처해서 만든다
cd "$(dirname "$0")"
SITE="https://lsyong941214.github.io"
TITLE="알뜰폰 약정 계산기"
DESC="개통일과 통신사를 넣으면 할인이 끝나는 날을 계산하고, 캘린더에 알림으로 등록해요."
mkdir -p docs
cp og.png docs/og.png
{
  cat <<EOF
<!doctype html>
<html lang="ko">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1,viewport-fit=cover">
<meta name="description" content="$DESC">
<meta property="og:type" content="website">
<meta property="og:site_name" content="$TITLE">
<meta property="og:title" content="$TITLE">
<meta property="og:description" content="$DESC">
<meta property="og:url" content="$SITE/">
<meta property="og:image" content="$SITE/og.png">
<meta property="og:image:width" content="1200">
<meta property="og:image:height" content="630">
<meta property="og:locale" content="ko_KR">
<meta name="twitter:card" content="summary_large_image">
EOF
  sed -n '1,/^<div class="wrap">/p' index.html | sed '$d' | grep -v 'claude:viewport-fit-sides'
  printf '</head>\n<body>\n'
  sed -n '/^<div class="wrap">/,$p' index.html
  printf '\n</body>\n</html>\n'
} > docs/index.html
echo "docs/index.html 생성 완료"

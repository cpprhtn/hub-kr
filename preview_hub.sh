#!/bin/bash

PREVIEW_DIR=_preview

# Clone pytorch.kr site source
echo '1. hub-kr 저장소 빌드를 위해 PyTorch.KR 홈페이지 저장소를 복제합니다...'
echo '   (기존에 복제한 저장소가 있으면 삭제 후 복제합니다.)'
if [ -d $PREVIEW_DIR ]; then
  rm -rf $PREVIEW_DIR
fi

git clone --recursive https://github.com/PyTorchKorea/pytorch.kr.git --depth 1 $PREVIEW_DIR
echo ' => 완료'

# Copy hub-kr files
echo '2. hub-kr 저장소 빌드를 위해 파일들을 복사합니다...'
cp *.md $PREVIEW_DIR/_hub
cp images/* $PREVIEW_DIR/assets/images/
echo ' => 완료'

# Build pytorch.kr site for preview
echo '3. PyTorch.KR 홈페이지를 빌드합니다...'
echo '   빌드가 되지 않는 경우 README.md 파일을 참조해주세요.'
echo '   (ruby, nodejs 및 의존성 설치가 필요합니다.)'
cd $PREVIEW_DIR
echo '4. _config.yml 및 Makefile 파일 수정...'
# _config.yml 파일 수정
sed -e '9i\#deployment' -e '10i\host: 0.0.0.0' -e '11i\port: 50001' _config.yml > _config.yml.tmp && mv _config.yml.tmp _config.yml

# Makefile 파일 수정
sed -e 's/git submodule update/#git submodule update/g; s/localhost:4000/0.0.0.0:50001/g' Makefile > Makefile.tmp && mv Makefile.tmp Makefile

rbenv local
make serve

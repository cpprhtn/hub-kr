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
#echo -e "# deployment \n host: 0.0.0.0 \n port: 50001" >> _config.yml
sed -e '6 i\#deployment' _config.yml > _config1.yml
sed -e '7 i\host: 0.0.0.0' _config1.yml > _config2.yml
sed -e '8 i\port: 50001' _config2.yml > _config3.yml
rm _config.yml _config1.yml _config2.yml
mv _config3.yml _config.yml
sed 's/git submodule update/#git submodule update/g' Makefile > Makefile.new
rm Makefile
mv Makefile.new Makefile
sed 's/localhost:4000/0.0.0.0:50001/g' Makefile > Makefile.new
rm Makefile
mv Makefile.new Makefile
rbenv local
#nvm use
make serve

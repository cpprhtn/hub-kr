---
layout: hub_detail
background-class: hub-background
body-class: hub
category: researchers
title: X3D
summary: X3D networks pretrained on the Kinetics 400 dataset
image: x3d.png
author: FAIR PyTorchVideo
tags: [vision]
github-link: https://github.com/facebookresearch/pytorchvideo
github-id: facebookresearch/pytorchvideo
featured_image_1: no-image
featured_image_2: no-image
accelerator: “cuda-optional”
demo-model-link: https://huggingface.co/spaces/pytorch/X3D
---

### 사용 예시

#### Imports

모델 불러오기:

```python
import torch
# `x3d_s` 모델 선택
model_name = 'x3d_s'
model = torch.hub.load('facebookresearch/pytorchvideo', model_name, pretrained=True)
```

나머지 함수들 불러오기:

```python
import json
import urllib
from pytorchvideo.data.encoded_video import EncodedVideo

from torchvision.transforms import Compose, Lambda
from torchvision.transforms._transforms_video import (
    CenterCropVideo,
    NormalizeVideo,
)
from pytorchvideo.transforms import (
    ApplyTransformToKey,
    ShortSideScale,
    UniformTemporalSubsample
)
```

#### 셋업

모델을 평가 모드로 설정하고 원하는 디바이스 방식을 선택합니다.

```python
# GPU 또는 CPU 방식을 설정합니다.
device = "cpu"
model = model.eval()
model = model.to(device)
```

토치 허브 모델이 훈련된 Kinetics 400 데이터셋에 대해 ID에서의 레이블 매핑 정보를 다운로드합니다. 이는 예측된 클래스 ID에서 카테고리 레이블 이름을 가져오는데 사용됩니다.

```python
json_url = "https://dl.fbaipublicfiles.com/pyslowfast/dataset/class_names/kinetics_classnames.json"
json_filename = "kinetics_classnames.json"
try: urllib.URLopener().retrieve(json_url, json_filename)
except: urllib.request.urlretrieve(json_url, json_filename)
```

```python
with open(json_filename, "r") as f:
    kinetics_classnames = json.load(f)

# 레이블 이름 매핑에 대한 ID 만들기
kinetics_id_to_classname = {}
for k, v in kinetics_classnames.items():
    kinetics_id_to_classname[v] = str(k).replace('"', "")
```

#### 입력 형태에 대한 정의

```python
mean = [0.45, 0.45, 0.45]
std = [0.225, 0.225, 0.225]
frames_per_second = 30
model_transform_params  = {
    "x3d_xs": {
        "side_size": 182,
        "crop_size": 182,
        "num_frames": 4,
        "sampling_rate": 12,
    },
    "x3d_s": {
        "side_size": 182,
        "crop_size": 182,
        "num_frames": 13,
        "sampling_rate": 6,
    },
    "x3d_m": {
        "side_size": 256,
        "crop_size": 256,
        "num_frames": 16,
        "sampling_rate": 5,
    }
}

# 모델에 맞는 변환 매개변수 가져오기
transform_params = model_transform_params[model_name]

# 이 변환은 slow_R50 모델에 한정됩니다.
transform =  ApplyTransformToKey(
    key="video",
    transform=Compose(
        [
            UniformTemporalSubsample(transform_params["num_frames"]),
            Lambda(lambda x: x/255.0),
            NormalizeVideo(mean, std),
            ShortSideScale(size=transform_params["side_size"]),
            CenterCropVideo(
                crop_size=(transform_params["crop_size"], transform_params["crop_size"])
            )
        ]
    ),
)

# 입력 클립의 길이는 모델에 따라 달라집니다.
clip_duration = (transform_params["num_frames"] * transform_params["sampling_rate"])/frames_per_second
```

#### 추론 실행

예제 영상을 다운로드합니다.

```python
url_link = "https://dl.fbaipublicfiles.com/pytorchvideo/projects/archery.mp4"
video_path = 'archery.mp4'
try: urllib.URLopener().retrieve(url_link, video_path)
except: urllib.request.urlretrieve(url_link, video_path)
```

영상을 불러오고 모델에 필요한 입력 형식으로 변환합니다.

```python
# 시작 및 종료 기간을 지정하여 불러올 클립의 기간을 선택합니다.
# start_sec는 영상에서 행동이 시작되는 위치와 일치해야합니다.
start_sec = 0
end_sec = start_sec + clip_duration

# EncodedVideo helper 클래스를 초기화하고 영상을 불러옵니다.
video = EncodedVideo.from_path(video_path)

# 원하는 클립을 불러옵니다.
video_data = video.get_clip(start_sec=start_sec, end_sec=end_sec)

# 영상 입력을 정규화하기 위해 변형(transform) 함수를 적용합니다.
video_data = transform(video_data)

# 입력을 원하는 디바이스로 이동합니다.
inputs = video_data["video"]
inputs = inputs.to(device)
```

#### 예측값 구하기

```python
# 모델을 통해 입력클립을 전달합니다.
preds = model(inputs[None, ...])

# 예측된 클래스를 가져옵니다.
post_act = torch.nn.Softmax(dim=1)
preds = post_act(preds)
pred_classes = preds.topk(k=5).indices[0]

# 예측된 클래스를 레이블 이름에 매핑합니다.
pred_class_names = [kinetics_id_to_classname[int(i)] for i in pred_classes]
print("Top 5 predicted labels: %s" % ", ".join(pred_class_names))
```

### 모델 설명
X3D 모델 아키텍처는 Kinetics 데이터셋에 대해 사전 훈련된 [1]을 기반으로 합니다.

| arch | depth | frame length x sample rate | top 1 | top 5 | Flops (G) | Params (M) |
| --------------- | ----------- | ----------- | ----------- | ----------- | ----------- |  ----------- | ----------- |
| X3D      | XS    | 4x12                       | 69.12 | 88.63 | 0.91      | 3.79     |
| X3D      | S     | 13x6                       | 73.33 | 91.27 | 2.96      | 3.79     |
| X3D      | M     | 16x5                       | 75.94 | 92.72 | 6.72      | 3.79     |


### 참고문헌
[1] Christoph Feichtenhofer, "X3D: Expanding Architectures for
    Efficient Video Recognition." https://arxiv.org/abs/2004.04730

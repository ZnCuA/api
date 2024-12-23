# 音频倒放API需求说明

## 接口说明
- 接口地址：/reverse-audio
- 请求方式：POST
- Content-Type: application/json

## 请求参数
```json
{
    "audio": "string",  // 音频文件的base64编码字符串
    "format": "string"  // 音频格式，如 "mp3"
}
```

## 响应格式
```json
{
    "code": 200,          // 状态码，200表示成功
    "message": "string",  // 状态信息
    "reversedAudio": "string"  // 倒放后的音频base64编码字符串
}
```

## 错误码说明
- 200: 成功
- 400: 请求参数错误
- 500: 服务器处理错误

## 技术要求
1. 支持的音频格式：
   - MP3
   - WAV
   - AAC

2. 音频处理要求：
   - 保持原有的音频质量
   - 保持原有的采样率
   - 最大支持文件大小：10MB
   - 最大处理时长：10秒

3. 性能要求：
   - 平均响应时间：<3秒
   - 并发处理能力：>100请求/分钟

## 示例
### 请求示例
```json
{
    "audio": "base64EncodedAudioString...",
    "format": "mp3"
}
```

### 成功响应示例
```json
{
    "code": 200,
    "message": "success",
    "reversedAudio": "base64EncodedReversedAudioString..."
}
```

### 错误响应示例
```json
{
    "code": 400,
    "message": "Invalid audio format",
    "reversedAudio": null
}
```
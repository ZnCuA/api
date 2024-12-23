from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
import base64
import io
from pydub import AudioSegment
import logging

# 配置日志
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = FastAPI(title="音频倒放API")

class AudioRequest(BaseModel):
    audio: str
    format: str

class AudioResponse(BaseModel):
    code: int
    message: str
    reversedAudio: str | None

SUPPORTED_FORMATS = {'mp3', 'wav', 'aac'}
MAX_FILE_SIZE = 10 * 1024 * 1024  # 10MB

@app.post("/reverse-audio", response_model=AudioResponse)
async def reverse_audio(request: AudioRequest):
    try:
        # 验证格式
        if request.format.lower() not in SUPPORTED_FORMATS:
            raise HTTPException(
                status_code=400,
                detail="不支持的音频格式"
            )

        # 解码base64
        try:
            audio_data = base64.b64decode(request.audio)
        except Exception as e:
            logger.error(f"Base64解码错误: {str(e)}")
            raise HTTPException(
                status_code=400,
                detail="无��的base64编码"
            )

        # 检查文件大小
        if len(audio_data) > MAX_FILE_SIZE:
            raise HTTPException(
                status_code=400,
                detail="文件大小超过10MB限制"
            )

        # 加载音频
        audio = AudioSegment.from_file(
            io.BytesIO(audio_data),
            format=request.format.lower()
        )

        # 检查音频时长
        if len(audio) > 10000:  # 10秒 = 10000毫秒
            raise HTTPException(
                status_code=400,
                detail="音频时长超过10秒限制"
            )

        # 倒放音频
        reversed_audio = audio.reverse()

        # 导出倒放后的音频
        output = io.BytesIO()
        reversed_audio.export(output, format=request.format.lower())
        
        # 转换为base64
        reversed_base64 = base64.b64encode(output.getvalue()).decode()

        return AudioResponse(
            code=200,
            message="success",
            reversedAudio=reversed_base64
        )

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"处理音频时发生错误: {str(e)}")
        raise HTTPException(
            status_code=500,
            detail="服务器处理错误"
        ) 
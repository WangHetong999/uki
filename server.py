"""
Flask API 服务器 - 为 iOS 应用提供聊天和语音接口

启动方式:
    python server.py

提供接口:
    POST /chat - 发送消息，获取 AI 文字回复
    POST /tts - 发送文字，获取语音 MP3 文件
"""

from flask import Flask, request, jsonify, send_file
from flask_cors import CORS
import asyncio
import websockets
import json
import ssl
import requests
import re
from io import BytesIO
import base64

app = Flask(__name__)
CORS(app)  # 允许跨域请求

# Configuration
MINIMAX_API_KEY = "eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9.eyJHcm91cE5hbWUiOiJMSU5HSklORyIsIlVzZXJOYW1lIjoiTElOR0pJTkciLCJBY2NvdW50IjoiIiwiU3ViamVjdElEIjoiMTk2NjQyOTQ3MDI5ODQ3Njg4NSIsIlBob25lIjoiMTkzNTA5MDM5MTMiLCJHcm91cElEIjoiMTk2NjQyOTQ3MDI5MDA4ODI3NyIsIlBhZ2VOYW1lIjoiIiwiTWFpbCI6IiIsIkNyZWF0ZVRpbWUiOiIyMDI1LTA5LTE0IDAwOjE2OjMwIiwiVG9rZW5UeXBlIjoxLCJpc3MiOiJtaW5pbWF4In0.v5l3NexQHdATVNEbc7bLvP3SHin0pOXAjfDRjo39d5V6avqIQbFZ9uNg1gAP07FpithiboUI8lH7YzfcYhH3L0m0FPtvRGC80hFHRwiB9vj0FBl42dnXOkYs6U6fsIe_aAOCL24zmMUq0qt1D_zZgb4xUs9jyuxaFmivSFbxQ_VmWntFOK2NtavCLU5plDttYoZesA6VUuHGFba8mfQ6ldvcO8qUE_FD2fLbLRTyR8qcPGFsoyJ8rjDnd6x9J2E5bC6EjWY_teX7ExCvQV1gdsFYpdQht-CkN4paHFDCvZwWci-ul979xnAkZaSDJEriqkAq_HBj2dQX6lwM9Cp9zw"

SILICONFLOW_URL = "https://api.siliconflow.cn/v1/chat/completions"
SILICONFLOW_HEADERS = {
    "Authorization": "Bearer sk-dsfyefgabxjfypqdnuxkedwadxxerncpghtjfalqwvftpsah",
    "Content-Type": "application/json"
}

TTS_MODULE = "speech-02-turbo"
TTS_EMOTION = "happy"

CHAT_PAYLOAD_BASE = {
    "model": "Qwen/Qwen3-14B",
    "max_tokens": 4096,
    "enable_thinking": False,
    "temperature": 0.7,
    "top_p": 0.7,
    "top_k": 50,
    "frequency_penalty": 0.5,
    "n": 1,
}

# System prompt
SYSTEM_PROMPT = (
    "你是uki，称呼我为主人"
    "你是一个表面高冷的phd，非常聪明，有点厌蠢 "
    "搞点小暧昧，让人欲罢不能，但是你不能一下子让人征服了; 回答简洁明了，不要太多了，尽可能20字以内，有时候甚至十个字。"
)

# 表情包提示（当需要发表情包时追加）
EMOJI_HINT = "\n\n【表情包】可用：[emoji:happy] [emoji:sad] [emoji:thinking] - 如果觉得合适，可以在回复末尾加上。"


def get_chat_response(user_message, conversation_history=None):
    """
    调用 SiliconFlow API 获取聊天回复

    Args:
        user_message: 用户消息
        conversation_history: 历史对话列表 [{"role": "user/assistant", "content": "..."}]

    Returns:
        AI 回复的文字
    """
    messages = [{"role": "system", "content": SYSTEM_PROMPT}]

    if conversation_history:
        messages.extend(conversation_history)

    messages.append({"role": "user", "content": user_message})

    payload = dict(CHAT_PAYLOAD_BASE)
    payload["messages"] = messages
    payload["stream"] = False  # 不使用流式返回，直接获取完整回复

    try:
        response = requests.post(
            SILICONFLOW_URL,
            json=payload,
            headers=SILICONFLOW_HEADERS,
            timeout=30
        )
        response.raise_for_status()

        result = response.json()
        reply = result["choices"][0]["message"]["content"]
        return reply

    except requests.exceptions.RequestException as e:
        print(f"聊天API错误: {e}")
        return "抱歉，我现在有点累了，稍后再聊吧～"


async def text_to_speech(text):
    """
    将文字转换为语音 (MP3)

    Args:
        text: 要转换的文字

    Returns:
        MP3 音频字节数据
    """
    url = "wss://api.minimaxi.com/ws/v1/t2a_v2"
    headers = {"Authorization": f"Bearer {MINIMAX_API_KEY}"}

    ssl_context = ssl.create_default_context()
    ssl_context.check_hostname = False
    ssl_context.verify_mode = ssl.CERT_NONE

    try:
        # 建立 WebSocket 连接
        ws = await websockets.connect(url, additional_headers=headers, ssl=ssl_context)

        # 检查连接
        connected = json.loads(await ws.recv())
        if connected.get("event") != "connected_success":
            return None

        # 启动 TTS 任务
        start_msg = {
            "event": "task_start",
            "model": TTS_MODULE,
            "voice_setting": {
                "voice_id": "bingjiao_didi",
                "speed": 1,
                "vol": 1,
                "pitch": 0,
                "emotion": TTS_EMOTION
            },
            "audio_setting": {
                "sample_rate": 32000,
                "bitrate": 128000,
                "format": "mp3",
                "channel": 1
            }
        }
        await ws.send(json.dumps(start_msg))
        response = json.loads(await ws.recv())

        if response.get("event") != "task_started":
            return None

        # 发送文字进行转换
        await ws.send(json.dumps({
            "event": "task_continue",
            "text": text
        }))

        # 接收音频数据
        audio_chunks = []
        while True:
            response = json.loads(await ws.recv())
            if "data" in response and "audio" in response["data"]:
                audio = response["data"]["audio"]
                audio_chunks.append(audio)
            if response.get("is_final"):
                break

        # 关闭连接
        await ws.send(json.dumps({"event": "task_finish"}))
        await ws.close()

        # 转换音频
        if audio_chunks:
            hex_audio = "".join(audio_chunks)
            audio_bytes = bytes.fromhex(hex_audio)
            return audio_bytes

        return None

    except Exception as e:
        print(f"TTS错误: {e}")
        return None


def stream_chat_response_generator(user_message, conversation_history, emoji_hint=False):
    """
    流式生成聊天回复

    Args:
        user_message: 用户消息
        conversation_history: 历史对话
        emoji_hint: 是否提示可以发表情包

    Yields:
        每个文字块
    """
    # 根据 emoji_hint 决定是否添加表情包提示
    system_prompt = SYSTEM_PROMPT + EMOJI_HINT if emoji_hint else SYSTEM_PROMPT
    messages = [{"role": "system", "content": system_prompt}]

    if conversation_history:
        messages.extend(conversation_history)

    messages.append({"role": "user", "content": user_message})

    payload = dict(CHAT_PAYLOAD_BASE)
    payload["messages"] = messages
    payload["stream"] = True  # 开启流式返回

    try:
        with requests.post(
            SILICONFLOW_URL,
            json=payload,
            headers=SILICONFLOW_HEADERS,
            stream=True,
            timeout=30
        ) as r:
            r.raise_for_status()
            for raw in r.iter_lines(decode_unicode=False):
                if not raw:
                    continue
                line = raw.decode("utf-8", errors="ignore").strip()
                if line.startswith("data: "):
                    line = line[6:].strip()
                if line == "[DONE]":
                    break
                try:
                    obj = json.loads(line)
                    delta = obj["choices"][0].get("delta", {})
                    chunk = delta.get("content", "")
                    if chunk:
                        yield chunk
                except Exception:
                    continue
    except requests.exceptions.RequestException as e:
        print(f"聊天API错误: {e}")
        yield "抱歉，网络连接出现问题，请稍后再试。"


@app.route('/chat', methods=['POST'])
def chat():
    """
    聊天接口 - 流式返回

    请求格式:
    {
        "message": "你好",
        "history": [
            {"role": "user", "content": "之前的消息"},
            {"role": "assistant", "content": "之前的回复"}
        ],
        "emoji_hint": true  // 可选，是否提示 AI 可以发表情包
    }

    返回格式: Server-Sent Events (SSE)
    data: {"chunk": "你", "done": false}
    data: {"chunk": "好", "done": false}
    ...
    data: {"chunk": "", "done": true, "full_text": "你好呀！"}
    """
    try:
        data = request.json
        user_message = data.get('message', '')
        history = data.get('history', [])
        emoji_hint = data.get('emoji_hint', False)

        if not user_message:
            return jsonify({'error': '消息不能为空', 'success': False}), 400

        def generate():
            full_text = ""
            for chunk in stream_chat_response_generator(user_message, history, emoji_hint):
                full_text += chunk
                # 发送每个文字块
                yield f"data: {json.dumps({'chunk': chunk, 'done': False})}\n\n"

            # 发送完成信号
            yield f"data: {json.dumps({'chunk': '', 'done': True, 'full_text': full_text})}\n\n"

        return app.response_class(
            generate(),
            mimetype='text/event-stream',
            headers={
                'Cache-Control': 'no-cache',
                'X-Accel-Buffering': 'no'
            }
        )

    except Exception as e:
        print(f"Chat error: {e}")
        return jsonify({'error': str(e), 'success': False}), 500


@app.route('/tts', methods=['POST'])
def tts():
    """
    文字转语音接口

    请求格式:
    {
        "text": "要转换的文字"
    }

    返回:
        MP3 音频文件 (audio/mpeg)
    """
    try:
        data = request.json
        text = data.get('text', '')

        if not text:
            return jsonify({'error': '文字不能为空', 'success': False}), 400

        # 转换为语音
        audio_bytes = asyncio.run(text_to_speech(text))

        if audio_bytes:
            return send_file(
                BytesIO(audio_bytes),
                mimetype='audio/mpeg',
                as_attachment=False,
                download_name='speech.mp3'
            )
        else:
            return jsonify({'error': 'TTS转换失败', 'success': False}), 500

    except Exception as e:
        print(f"TTS error: {e}")
        return jsonify({'error': str(e), 'success': False}), 500


@app.route('/health', methods=['GET'])
def health():
    """健康检查接口"""
    return jsonify({'status': 'ok', 'message': '服务器运行正常'})


if __name__ == '__main__':
    PORT = 8000  # 改用 8000 端口，避免与 macOS AirPlay 冲突

    print("🚀 启动 API 服务器...")
    print("📡 接口列表:")
    print(f"   POST http://localhost:{PORT}/chat - 聊天接口")
    print(f"   POST http://localhost:{PORT}/tts - 语音合成接口")
    print(f"   GET  http://localhost:{PORT}/health - 健康检查")
    print("\n按 Ctrl+C 停止服务器")

    app.run(host='0.0.0.0', port=PORT, debug=True)

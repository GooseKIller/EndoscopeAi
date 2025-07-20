import asyncio
import websockets
import speech_recognition as sr
from queue import Queue
import threading
import logging

logging.basicConfig(level=logging.INFO)
result_queue = Queue()

def recognize_worker():
    r = sr.Recognizer()
    mic = sr.Microphone(device_index=1)  # Укажите ваш индекс
    
    with mic as source:
        logging.info("Calibrating microphone...")
        r.adjust_for_ambient_noise(source, duration=1)
        logging.info("Ready for commands. Say 'start recording', 'stop recording' or 'take photo'")
        
        while True:
            try:
                audio = r.listen(source, phrase_time_limit=3)
                text = r.recognize_google(audio, language="ru-RU").lower()
                logging.info(f"Recognized: {text}")
                result_queue.put(text)
            except sr.UnknownValueError:
                logging.warning("Speech not recognized")
            except sr.RequestError as e:
                logging.error(f"API error: {e}")
            except Exception as e:
                logging.error(f"Error: {e}")

async def ws_handler(websocket):
    logging.info("New connection")
    while True:
        if not result_queue.empty():
            text = result_queue.get()
            await websocket.send(text)
        await asyncio.sleep(0.1)

async def main():
    # Запускаем поток для распознавания речи
    threading.Thread(target=recognize_worker, daemon=True).start()
    
    # Запускаем WebSocket сервер
    async with websockets.serve(ws_handler, "localhost", 8765):
        logging.info("WebSocket server started on ws://localhost:8765")
        await asyncio.Future()  # Бесконечное ожидание

if __name__ == "__main__":
    asyncio.run(main())  # Используем asyncio.run() вместо get_event_loop()
from fastapi import APIRouter, UploadFile, File, Form, HTTPException
from ultralytics import YOLO
from PIL import Image
import io
import os
import numpy as np
import cv2
import base64
import time
from pathlib import Path
from dotenv import load_dotenv
from groq import Groq
from supabase import create_client, Client

load_dotenv(dotenv_path=Path(__file__).parent.parent / ".env")

router = APIRouter()

# ==========================================
# 1. CONFIGURAZIONE CHIAVI E CLIENT
# ==========================================

# A) GROQ (Vision AI)
GROQ_API_KEY = os.getenv("GROQ_API_KEY")
client = Groq(api_key=GROQ_API_KEY)

# B) SUPABASE (Database)
SUPABASE_URL = os.getenv("SUPABASE_URL")
SUPABASE_KEY = os.getenv("SUPABASE_ANON_KEY")
supabase: Client = create_client(SUPABASE_URL, SUPABASE_KEY)

# C) YOLO (Visione Veloce)
try:
    medicine_model = YOLO("medicine_best.pt") # Usa il tuo se presente
except:
    print("⚠️ Modello medicine_best.pt non trovato, uso yolov8n.pt")
    medicine_model = YOLO("yolov8n.pt")

general_model = YOLO("yolov8n.pt")

# ==========================================
# 2. MEMORIA A BREVE TERMINE (SEMAFORO)
# ==========================================
# Serve per evitare di chiamare le API costose 30 volte al secondo
last_analysis_time = 0
last_detected_name = None
COOLDOWN_SECONDS = 5  # Secondi di attesa tra una chiamata AI e l'altra

# ==========================================
# 3. FUNZIONI DI SUPPORTO
# ==========================================

def verify_medicine_in_db(medicine_name, patient_id=None):
    """
    Controlla se il farmaco esiste su Supabase.
    - Se patient_id è fornito: cerca SOLO tra i farmaci di quel paziente.
    - Se patient_id è None: cerca in tutta la tabella (comportamento vecchio).
    """
    try:
        clean_name = medicine_name.strip().replace(".", "")
        print(f"🔎 Cerco '{clean_name}' su Supabase (Patient ID: {patient_id})...")

        query = supabase.table('medications').select("*").ilike('name', f"%{clean_name}%")
        
        # --- MODIFICA QUI: Filtra per paziente se l'ID è presente ---
        if patient_id:
            query = query.eq('patient_id', patient_id)
        # ------------------------------------------------------------

        response = query.execute()

        if response.data and len(response.data) > 0:
            official_name = response.data[0]['name']
            print(f"✅ Trovato e validato per il paziente: {official_name}")
            return official_name
        else:
            print(f"⚠️ '{clean_name}' NON trovato (o non assegnato a questo paziente).")
            return None

    except Exception as e:
        print(f"❌ Errore Supabase: {e}")
        return None

def analyze_with_groq(image_bytes):
    """
    Invia l'immagine a Groq (Llama Vision) per leggere l'etichetta.
    """
    try:
        base64_image = base64.b64encode(image_bytes).decode('utf-8')
        
        completion = client.chat.completions.create(
            model="meta-llama/llama-4-maverick-17b-128e-instruct",
            messages=[
                {
                    "role": "user",
                    "content": [
                        {
                            "type": "text", 
                            "text": "Analizza l'immagine. È un farmaco o integratore? Se SÌ, rispondi SOLO col nome commerciale esatto (es. 'Tachipirina', 'Brufen'). Se NO (es. acqua, vuoto), rispondi 'NULL'."
                        },
                        {
                            "type": "image_url",
                            "image_url": {
                                "url": f"data:image/jpeg;base64,{base64_image}"
                            }
                        }
                    ]
                }
            ],
            temperature=0,
            max_tokens=30
        )
        return completion.choices[0].message.content.strip()
    except Exception as e:
        print(f"❌ Errore Groq: {e}")
        return "NULL"

# ==========================================
# 4. ENDPOINT PRINCIPALE
# ==========================================

@router.post("/detect-objects")
async def detect_objects(file: UploadFile = File(...), mode: str = Form("general"), patient_id: str = Form(None)):
    global last_analysis_time, last_detected_name
    
    try:
        # Legge il file immagine
        contents = await file.read()
        
        # Converte per YOLO (OpenCV format)
        nparr = np.frombuffer(contents, np.uint8)
        img = cv2.imdecode(nparr, cv2.IMREAD_COLOR)

        # Seleziona modello
        model = medicine_model if mode == "medicine" else general_model
        results = model(img, verbose=False)

        detected_objects = []
        current_time = time.time()

        for result in results:
            for box in result.boxes:
                # Dati base da YOLO
                class_id = int(box.cls[0])
                original_label = model.names[class_id] # es. 'bottle'
                confidence = float(box.conf[0])
                
                # Etichetta finale da inviare all'App (di base è quella di YOLO)
                final_label = original_label 

                # --- LOGICA INTELLIGENTE ---
                # Se YOLO vede qualcosa che assomiglia a un farmaco
                if original_label in ['bottle', 'medicine', 'cup', 'can', 'book'] and confidence > 0.4:
                    
                    # 1. Controlliamo se è passato il tempo di attesa (Semaforo Verde)
                    if (current_time - last_analysis_time) > COOLDOWN_SECONDS:
                        print(f"🔍 YOLO vede {original_label}. Chiedo a Groq...")
                        
                        # 2. Chiamata all'LLM (Groq)
                        groq_name = analyze_with_groq(contents)
                        
                        if groq_name and "NULL" not in groq_name:
                            print(f"🤖 Groq dice: {groq_name}. Verifico DB...")
                            
                            # 3. Verifica nel Database (Supabase)
                            db_name = verify_medicine_in_db(groq_name, patient_id)
                            
                            if db_name:
                                # CASO A: Trovato nel DB -> Restituisco il nome pulito
                                final_label = f"MEDICINE:{db_name}"
                            else:
                                # CASO B: Non trovato -> Restituisco con prefisso speciale
                                final_label = f"UNKNOWN: {groq_name}"
                            
                            # Aggiorno la memoria
                            last_detected_name = final_label
                            last_analysis_time = current_time
                        else:
                            # Groq non ha visto farmaci
                            print("❌ Groq non ha rilevato nomi di farmaci.")
                            last_analysis_time = current_time 
                    
                    # 4. Se il semaforo è Rosso, usiamo la memoria recente
                    elif last_detected_name and (current_time - last_analysis_time) < COOLDOWN_SECONDS:
                        final_label = last_detected_name

                # --- FORMATTAZIONE RISPOSTA (Compatibile con il tuo vision_service.dart) ---
                detected_objects.append({
                    "class_id": class_id,
                    "class_name": final_label,  # <-- Qui finisce "Tachipirina" o "UNKNOWN: ..."
                    "confidence": confidence,
                    "bounding_box": dict(zip(
                        ["x1", "y1", "x2", "y2"],
                        box.xyxy[0].tolist()
                    ))
                })

        # Risposta JSON standard
        return {
            "objects_detected": len(detected_objects),
            "objects": detected_objects
        }

    except Exception as e:
        print(f"🔥 Critical Error: {e}")
        raise HTTPException(status_code=500, detail=str(e))
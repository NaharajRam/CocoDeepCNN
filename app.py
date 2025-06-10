import os
import io
from flask import Flask, request, jsonify, send_from_directory
from flask_cors import CORS
import numpy as np
from PIL import Image
import tensorflow as tf

# Initialize Flask
app = Flask(__name__)
CORS(app)

# Paths and model setup
BASE_DIR = os.path.dirname(os.path.abspath(__file__))
MODEL_PATH = os.path.join(BASE_DIR, "vgg19_model.tflite")

if not os.path.exists(MODEL_PATH):
    raise FileNotFoundError(f"Model not found at {MODEL_PATH}")

# Load TFLite model
interpreter = tf.lite.Interpreter(model_path=MODEL_PATH)
interpreter.allocate_tensors()
input_details = interpreter.get_input_details()
output_details = interpreter.get_output_details()

# Labels list
labels = [
    'WCLWD_DryingofLeaflets',
    'WCLWD_Flaccidity',
    'WCLWD_Yellowing',
    'bud root dropping',
    'bud rot',
    'gray leaf spot',
    'healthy_leaves',
    'leaf rot',
    'stem bleeding'
]

# Directory for uploaded files
UPLOAD_FOLDER = os.path.join(BASE_DIR, "uploads")
if not os.path.exists(UPLOAD_FOLDER):
    os.makedirs(UPLOAD_FOLDER)
app.config['UPLOAD_FOLDER'] = UPLOAD_FOLDER

# Preprocess image for model
def preprocess_image(image_bytes):
    img = Image.open(io.BytesIO(image_bytes)).convert("RGB")
    img = img.resize((224, 224))
    arr = np.array(img, dtype=np.float32) / 255.0
    return np.expand_dims(arr, axis=0)

# Health check
@app.route("/ping", methods=["GET"])
def ping():
    return "pong", 200

# Prediction endpoint
@app.route("/predict", methods=["POST"])
def predict():
    if "file" not in request.files:
        return jsonify({"error": "No file uploaded"}), 400

    file = request.files["file"]
    image_bytes = file.read()
    input_tensor = preprocess_image(image_bytes)

    # Save uploaded image
    file_path = os.path.join(app.config['UPLOAD_FOLDER'], file.filename)
    with open(file_path, 'wb') as f:
        f.write(image_bytes)
    
    # Model inference
    interpreter.set_tensor(input_details[0]["index"], input_tensor)
    interpreter.invoke()
    output_data = interpreter.get_tensor(output_details[0]["index"])[0]

    idx = int(np.argmax(output_data))
    confidence = float(output_data[idx])
    raw_label = labels[idx]

    # Map to "coconut wilt" if applicable
    wilt_labels = {'WCLWD_DryingofLeaflets', 'WCLWD_Flaccidity', 'WCLWD_Yellowing'}
    final_label = "coconut wilt" if raw_label in wilt_labels else raw_label

    # Prepare response
    image_url = f"/uploads/{file.filename}"
    prediction = {
        "label": final_label,
        "confidence": round(confidence, 4),
        "image_url": image_url
    }

    return jsonify(prediction)

# Serve uploaded images
@app.route('/uploads/<filename>')
def uploaded_file(filename):
    return send_from_directory(app.config['UPLOAD_FOLDER'], filename)

# Run server
if __name__ == "__main__":
    app.run(debug=True)

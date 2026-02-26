import easyocr
import cv2
import numpy as np
import supervision as sv

class OCREngine:
    def __init__(self, gpu=False):
        """
        Initializes the EasyOCR reader once.
        Loading the model is heavy, so we do it only when the class is created.
        """
        print("Loading OCR Model...")
        self.reader = easyocr.Reader(['en'], gpu=gpu)
        self.box_annotator = sv.BoxAnnotator(thickness=2)
        self.label_annotator = sv.LabelAnnotator(text_thickness=2, text_scale=0.5)
        print("OCR Model Loaded.")

    def scan_image(self, image_source):
        """
        Scans an image for text.
        Args:
            image_source: Can be a file path (str) or a NumPy array (image).
        Returns:
            dict: Contains 'detections' (list of found text) and 'annotated_image' (visual).
        """
        # 1. Load Image
        if isinstance(image_source, str):
            image = cv2.imread(image_source)
            if image is None:
                raise ValueError(f"Could not read image at path: {image_source}")
        elif isinstance(image_source, np.ndarray):
            image = image_source
        else:
            raise TypeError("Image source must be a file path (str) or a NumPy array.")

        # 2. Perform OCR
        results = self.reader.readtext(image)

        # 3. Parse Data for Supervision & API
        xyxy = []
        confidences = []
        class_ids = []
        labels = []
        clean_data = []

        for detection in results:
            bbox, text, confidence = detection
            
            # Normalize coordinates to integers
            x_min = int(min([p[0] for p in bbox]))
            y_min = int(min([p[1] for p in bbox]))
            x_max = int(max([p[0] for p in bbox]))
            y_max = int(max([p[1] for p in bbox]))

            xyxy.append([x_min, y_min, x_max, y_max])
            labels.append(text)
            confidences.append(confidence)
            class_ids.append(0)
            
            # Save clean data for the App
            clean_data.append({
                "text": text,
                "confidence": round(float(confidence), 2),
                "box": [x_min, y_min, x_max, y_max]
            })

        # 4. Annotate Image (Visual Feedback)
        if len(xyxy) > 0:
            detections = sv.Detections(
                xyxy=np.array(xyxy),
                confidence=np.array(confidences),
                class_id=np.array(class_ids)
            )
            annotated_image = self.box_annotator.annotate(scene=image.copy(), detections=detections)
            annotated_image = self.label_annotator.annotate(scene=annotated_image, detections=detections, labels=labels)
        else:
            annotated_image = image.copy()

        return {
            "data": clean_data,
            "annotated_image": annotated_image
        }

# --- TEST BLOCK ---
# This only runs if you run "python ocr_engine.py" directly.
# It will NOT run when you import this file into your API.
if __name__ == "__main__":
    engine = OCREngine()
    
    # Test with a local file
    try:
        result = engine.scan_image("test_image.jpg") # Replace with a real path to test
        print("Found text:", [item['text'] for item in result['data']])
        cv2.imwrite("debug_output.jpg", result['annotated_image'])
        print("Saved annotated image to debug_output.jpg")
    except Exception as e:
        print(f"Test failed: {e}")
# from ultralytics import YOLO
# import numpy as np
# import cv2
# from ultralytics.utils.plotting import Annotator

# def seeLand(imageUrl):
#     # model = YOLO('yolov8m.pt')
#     model = YOLO('yolov8m-oiv7.pt')
#     # model = YOLO('yolov8m-cls.pt')
#     # print (model.info())
#     # Train the model using the 'coco128.yaml' dataset for 3 epochs
#     # results = model.train(data='coco128.yaml', epochs=3)
#     # Evaluate the model's performance on the validation set
#     # results = model.val()
#     # Perform object detection on an image using the model
#     results = model(imageUrl)
#     # print ('results', results)
#     # for result in results:
#     #     for box in result.boxes:
#     #         print ('box', box)
#     img = cv2.imread(imageUrl)
#     for r in results:
#         annotator = Annotator(np.ascontiguousarray(img))
#         boxes = r.boxes
#         for box in boxes:
#             b = box.xyxy[0]  # get box coordinates in (top, left, bottom, right) format
#             c = box.cls
#             annotator.box_label(b, model.names[int(c)])

#     img = annotator.result()  
#     cv2.imwrite('./uploads/land-vision-boxed.jpg', img)

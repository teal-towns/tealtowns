# import tensorflow as tf
import keras


def preprocess_RGB(images):
    bgr = keras.applications.vgg16.preprocess_input(images[:,:,:,:3])
    return bgr


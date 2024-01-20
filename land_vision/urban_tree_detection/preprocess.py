import tensorflow as tf


def preprocess_RGB(images):
    bgr = tf.keras.applications.vgg16.preprocess_input(images[:,:,:,:3])
    return bgr


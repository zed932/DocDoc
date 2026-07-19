import argparse
import numpy as np
import math

from PIL import Image
from ai_edge_litert.compiled_model import CompiledModel

def litert_inference(ckpt_path: str, image_path: str, save_path: str):
    # Prepare model
    model = CompiledModel.from_file(ckpt_path)
    
    # Prepare Image
    pil_img = Image.open(image_path)
    numpy_img = np.array(pil_img, dtype=np.float32) / 255
    numpy_img = np.ascontiguousarray(np.expand_dims(numpy_img.transpose(2, 0, 1), axis=0))
    
    # Preparing buffers
    # {'serving_default': {'inputs': ['args_0'], 'outputs': ['output_0']}} - model signature
    signature_index = 0
    input_buffers = model.create_input_buffers(signature_index)
    output_buffers = model.create_output_buffers(signature_index)
    input_buffers[0].write(numpy_img)
    
    model.run_by_index(signature_index, input_buffers, output_buffers)
    
    output_shape = numpy_img.shape 
    num_elements = math.prod(output_shape)
    output_array_flat = output_buffers[0].read(num_elements, np.float32)
    output_array = output_array_flat.reshape(output_shape)
    
    output_array = (output_array.squeeze(0).transpose(1, 2, 0) * 255).astype(np.uint8)
    output_pil = Image.fromarray(output_array)
    output_pil.save(save_path)
    
if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    
    parser.add_argument('--model_path', type=str, default='./converted/model.tflite')
    parser.add_argument('--img_path', type=str, default='./input/for_dewarping.png')
    parser.add_argument('--save_path', type=str, default='./output/litert_image.png')
    
    args = parser.parse_args()
    
    litert_inference(args.model_path, args.img_path, args.save_path)